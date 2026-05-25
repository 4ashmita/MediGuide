import Foundation

enum ScoringCalculator {

    static func symptomTotal(from symptoms: [Symptom]) -> Int {
        symptoms.reduce(0) { $0 + $1.weight }
    }

    static func modifierTotal(from modifiers: [Modifier]) -> Int {
        modifiers.reduce(0) { $0 + $1.weight }
    }

    static func applyAgeMultiplier(to score: Int, for ageGroup: AgeGroup) -> Int {
        Int((Double(score) * ageGroup.scoreMultiplier).rounded())
    }

    static func mapToTier(score: Int, tiers: [String: DecisionTreeData.TierConfig]) -> RecommendationTier {
        tiers
            .compactMap { key, config -> (RecommendationTier, Int)? in
                guard let tier = RecommendationTier(rawValue: key) else { return nil }
                return (tier, config.minScore)
            }
            .filter { score >= $0.1 }
            .max(by: { $0.1 < $1.1 })
            .map { $0.0 } ?? .monitor
    }

    static func escalateTier(_ current: RecommendationTier) -> RecommendationTier {
        switch current {
        case .monitor:    return .urgentCare
        case .urgentCare: return .goToER
        case .goToER:     return .call911
        case .call911:    return .call911
        }
    }
}
