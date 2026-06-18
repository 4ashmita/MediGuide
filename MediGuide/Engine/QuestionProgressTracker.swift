import Foundation

struct QuestionProgressTracker {
    let questionNumber: Int
    let estimatedProgress: Double

    // Typical path through the tree is 5–6 questions; cap progress at 0.95
    // so the bar never looks "done" before the result screen appears.
    private static let estimatedTotal: Double = 6

    init(questionNumber: Int) {
        self.questionNumber = questionNumber
        self.estimatedProgress = min(Double(questionNumber - 1) / Self.estimatedTotal, 0.95)
    }
}
