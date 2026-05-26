import Foundation
import Combine

final class TriageEngine: ObservableObject {

    // MARK: - Published State

    @Published private(set) var session = TriageSession()
    @Published private(set) var currentTier: RecommendationTier = .monitor
    @Published private(set) var warningSigns: [String] = []

    // MARK: - Private

    private let treeData: DecisionTreeData

    // MARK: - Init

    init(treeData: DecisionTreeData) {
        self.treeData = treeData
        evaluate()
    }

    // MARK: - Public Interface

    func addSymptom(_ id: String) {
        guard !session.symptoms.contains(where: { $0.symptomId == id }),
              let weight = treeData.symptomWeights[id] else { return }
        session.symptoms.append(Symptom(symptomId: id, weight: weight))
        evaluate()
    }

    func removeSymptom(_ id: String) {
        session.symptoms.removeAll { $0.symptomId == id }
        session.hardOverrideTriggered = session.symptoms.contains {
            treeData.hardOverrides.contains($0.symptomId)
        }
        evaluate()
    }

    func addModifier(_ id: String) {
        guard !session.modifiers.contains(where: { $0.modifierId == id }),
              let weight = treeData.modifierWeights[id] else { return }
        session.modifiers.append(Modifier(modifierId: id, weight: weight))
        evaluate()
    }

    func removeModifier(_ id: String) {
        session.modifiers.removeAll { $0.modifierId == id }
        evaluate()
    }

    func setAgeGroup(_ group: AgeGroup) {
        session.ageGroup = group
        evaluate()
    }

    func triggerInstinctOverride() {
        guard currentTier != .call911 else { return }
        session.instinctOverrideUsed = true
        session.escalationCount += 1
        evaluate()
    }

    // Returns true if timer should restart, false if escalation took over
    @discardableResult
    func reassess(response: ReassessmentResponse, minutesElapsed: Int) -> Bool {
        let timestamp = "+\(minutesElapsed)min: \(response)"
        session.reassessmentHistory.append(timestamp)
        session.reassessmentCount += 1

        switch response {
        case .better:
            return true

        case .worse:
            addModifier("symptoms_worsening")
            escalateOnReassessment()
            return false

        case .sameMonitor:
            if minutesElapsed >= 240 {
                addModifier("symptoms_not_improving")
                escalateOnReassessment()
                return false
            } else if minutesElapsed >= 120 && session.reassessmentCount >= 2 {
                addModifier("symptoms_not_improving")
                escalateOnReassessment()
                return false
            }
            return true

        case .sameOnWay:
            return true

        case .sameNotGone:
            if currentTier == .urgentCare && minutesElapsed >= 60 {
                addModifier("symptoms_not_improving")
                escalateOnReassessment()
                return false
            }
            return true

        case .cantTravel:
            while currentTier != .call911 {
                escalateOnReassessment()
            }
            return false
        }
    }

    private func escalateOnReassessment() {
        guard currentTier != .call911 else { return }
        session.escalatedViaReassessment = true
        session.escalationCount += 1
        evaluate()
    }

    func reset() {
        session = TriageSession()
        evaluate()
    }

    // MARK: - Scoring

    private func checkHardOverrides() -> Bool {
        session.symptoms.contains {
            treeData.hardOverrides.contains($0.symptomId)
        }
    }

    private func evaluate() {
        if checkHardOverrides() {
            session.hardOverrideTriggered = true
            session.totalScore = Int.max
            applyTier(.call911)
            return
        }

        let base = ScoringCalculator.symptomTotal(from: session.symptoms)
                 + ScoringCalculator.modifierTotal(from: session.modifiers)
        session.totalScore = ScoringCalculator.applyAgeMultiplier(to: base, for: session.ageGroup)

        var tier = ScoringCalculator.mapToTier(score: session.totalScore, tiers: treeData.recommendationTiers)

        for _ in 0 ..< session.escalationCount {
            tier = ScoringCalculator.escalateTier(tier)
        }

        applyTier(tier)
    }

    private func applyTier(_ tier: RecommendationTier) {
        currentTier = tier
        warningSigns = WarningSignsProvider.getWarningSigns(tier: tier, symptoms: session.symptoms)
    }
}
