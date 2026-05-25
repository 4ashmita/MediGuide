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
        guard !session.instinctOverrideUsed else { return }
        session.instinctOverrideUsed = true
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

        if session.instinctOverrideUsed {
            tier = ScoringCalculator.escalateTier(tier)
        }

        applyTier(tier)
    }

    private func applyTier(_ tier: RecommendationTier) {
        currentTier = tier
        warningSigns = treeData.warningSigns[tier.rawValue] ?? []
    }
}
