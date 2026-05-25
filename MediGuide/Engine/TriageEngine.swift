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
        addModifier("instinct_override")
    }

    func reset() {
        session = TriageSession()
        evaluate()
    }

    // MARK: - Scoring

    private func evaluate() {
        let hardOverrideHit = session.symptoms.contains {
            treeData.hardOverrides.contains($0.symptomId)
        }

        if hardOverrideHit {
            session.hardOverrideTriggered = true
            session.totalScore = Int.max
            applyTier(.call911)
            return
        }

        let symptomTotal = session.symptoms.reduce(0) { $0 + $1.weight }
        let modifierTotal = session.modifiers.reduce(0) { $0 + $1.weight }
        let rawScore = Double(symptomTotal + modifierTotal) * session.ageGroup.scoreMultiplier
        session.totalScore = Int(rawScore.rounded())

        let tier = treeData.recommendationTiers
            .compactMap { key, config -> (RecommendationTier, Int)? in
                guard let tier = RecommendationTier(rawValue: key) else { return nil }
                return (tier, config.minScore)
            }
            .filter { session.totalScore >= $0.1 }
            .max(by: { $0.1 < $1.1 })
            .map { $0.0 } ?? .monitor

        applyTier(tier)
    }

    private func applyTier(_ tier: RecommendationTier) {
        currentTier = tier
        warningSigns = treeData.warningSigns[tier.rawValue] ?? []
    }
}
