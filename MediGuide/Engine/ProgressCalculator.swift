import SwiftUI

enum ProgressCalculator {
    // Typical branching tree path: 5–8 questions; use 7.5 as a balanced estimate.
    private static let estimatedMaxQuestions: Double = 7.5
    // Average seconds per tap-based answer.
    private static let secondsPerQuestion: Double = 4

    /// Returns bar progress (0–1), bar color, score dot color, and time estimate string.
    static func calculate(
        questionNumber: Int,
        currentTier: RecommendationTier,
        hardOverride: Bool,
        isComplete: Bool,
        symptomCount: Int,
        modifierCount: Int
    ) -> (progress: Double, barColor: Color, dotColor: Color, timeEstimate: String?) {
        if hardOverride || isComplete {
            return (1.0, tierColor(.call911), tierColor(.call911), nil)
        }

        let questionProgress = min(Double(questionNumber - 1) / estimatedMaxQuestions, 0.90)

        let tierWeight: Double
        switch currentTier {
        case .monitor:    tierWeight = 0.05
        case .urgentCare: tierWeight = 0.35
        case .goToER:     tierWeight = 0.60
        case .call911:    tierWeight = 1.00
        }

        // Question depth contributes 40%, score tier contributes 60%.
        let combined = min(questionProgress * 0.40 + tierWeight * 0.60, 0.95)

        let bar = tierColor(currentTier)
        let dot = dotColor(currentTier, symptomCount: symptomCount)
        let estimate = timeEstimate(questionNumber: questionNumber)

        return (combined, bar, dot, estimate)
    }

    // MARK: - Color

    static func tierColor(_ tier: RecommendationTier) -> Color {
        switch tier {
        case .monitor:    return Color(red: 0.20, green: 0.50, blue: 0.90)
        case .urgentCare: return Color(red: 0.35, green: 0.70, blue: 0.30)
        case .goToER:     return Color(red: 0.95, green: 0.55, blue: 0.10)
        case .call911:    return Color(red: 0.94, green: 0.10, blue: 0.10)
        }
    }

    private static func dotColor(_ tier: RecommendationTier, symptomCount: Int) -> Color {
        symptomCount == 0 ? Color.gray.opacity(0.35) : tierColor(tier)
    }

    // MARK: - Time estimate

    private static func timeEstimate(questionNumber: Int) -> String? {
        let remaining = max(0, estimatedMaxQuestions - Double(questionNumber - 1))
        let seconds = remaining * secondsPerQuestion
        if seconds <= 12 { return "Almost done" }
        let mins = max(1, Int((seconds / 60).rounded()))
        return "About \(mins) minute\(mins == 1 ? "" : "s") remaining"
    }
}
