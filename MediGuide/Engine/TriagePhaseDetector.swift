import Foundation

enum TriagePhaseDetector {
    /// Determines the current triage phase from session state.
    /// Phase is based on question depth, symptom accumulation, and score direction —
    /// never on a known total question count (which is unknowable in a branching tree).
    static func detect(
        questionNumber: Int,
        symptomCount: Int,
        modifierCount: Int,
        currentTier: RecommendationTier,
        hardOverride: Bool,
        isComplete: Bool
    ) -> ProgressState.Phase {
        if hardOverride || isComplete { return .recommendationReady }
        if currentTier == .call911   { return .recommendationReady }
        if questionNumber >= 8       { return .recommendationReady }

        if currentTier == .goToER   { return .riskEvaluation }
        if modifierCount >= 2       { return .riskEvaluation }
        if questionNumber >= 5 && symptomCount >= 1 { return .riskEvaluation }

        if symptomCount >= 1        { return .symptomIdentification }
        if questionNumber >= 3      { return .symptomIdentification }

        return .initialAssessment
    }
}
