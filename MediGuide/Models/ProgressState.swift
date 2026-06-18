import SwiftUI

struct ProgressState {
    enum Phase: String {
        case initialAssessment     = "Initial Assessment"
        case symptomIdentification = "Identifying Symptoms"
        case riskEvaluation        = "Evaluating Risk Factors"
        case recommendationReady   = "Almost There"
    }

    let phase: Phase
    /// 0.0–1.0; enforced never-decreasing by TriageProgressViewModel
    let barProgress: Double
    let barColor: Color
    /// "Question 4" / "Analyzing description" / "" when hard override fires
    let questionLabel: String
    /// Neutral gray until score accumulates, then tier-matched color
    let tierDotColor: Color
    /// "About 1 minute remaining" / "Almost done" / nil during NLP
    let timeEstimate: String?
    let isHardOverride: Bool
    let isProcessing: Bool

    static let initial = ProgressState(
        phase: .initialAssessment,
        barProgress: 0,
        barColor: .blue,
        questionLabel: "Question 1",
        tierDotColor: Color.gray.opacity(0.4),
        timeEstimate: "About 1 minute remaining",
        isHardOverride: false,
        isProcessing: false
    )
}
