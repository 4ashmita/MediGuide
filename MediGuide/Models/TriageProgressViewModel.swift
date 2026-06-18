import Foundation
import Combine
import SwiftUI

@MainActor
final class TriageProgressViewModel: ObservableObject {
    @Published private(set) var state: ProgressState = .initial

    private var highwaterProgress: Double = 0
    private var cancellables = Set<AnyCancellable>()

    init(engine: TriageEngine, navigationManager: NavigationManager) {
        Publishers.CombineLatest3(engine.$session, engine.$currentTier, navigationManager.$currentNode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak engine, weak navigationManager] _, _, _ in
                guard let self, let engine, let navigationManager else { return }
                self.update(engine: engine, navigationManager: navigationManager)
            }
            .store(in: &cancellables)
    }

    func markProcessing(label: String) {
        state = ProgressState(
            phase: state.phase,
            barProgress: state.barProgress,
            barColor: state.barColor,
            questionLabel: label,
            tierDotColor: Color.gray.opacity(0.35),
            timeEstimate: "A moment...",
            isHardOverride: false,
            isProcessing: true
        )
    }

    // MARK: - Private

    private func update(engine: TriageEngine, navigationManager: NavigationManager) {
        let session = engine.session
        let questionNumber = navigationManager.questionNumber
        let hardOverride = session.hardOverrideTriggered
        let isComplete = navigationManager.isComplete
        let symptomCount = session.symptoms.count
        let modifierCount = session.modifiers.count

        // Detect a fresh session reset: back at Q1 with cleared state and stale highwater.
        if questionNumber == 1 && symptomCount == 0 && modifierCount == 0 && highwaterProgress > 0.15 {
            highwaterProgress = 0
        }

        let (rawProgress, barColor, dotColor, timeEstimate) = ProgressCalculator.calculate(
            questionNumber: questionNumber,
            currentTier: engine.currentTier,
            hardOverride: hardOverride,
            isComplete: isComplete,
            symptomCount: symptomCount,
            modifierCount: modifierCount
        )

        // Bar never goes backward.
        if hardOverride || isComplete {
            highwaterProgress = 1.0
        } else {
            highwaterProgress = max(highwaterProgress, rawProgress)
        }

        let phase = TriagePhaseDetector.detect(
            questionNumber: questionNumber,
            symptomCount: symptomCount,
            modifierCount: modifierCount,
            currentTier: engine.currentTier,
            hardOverride: hardOverride,
            isComplete: isComplete
        )

        let questionLabel: String
        if hardOverride || isComplete {
            questionLabel = ""
        } else {
            questionLabel = "Question \(questionNumber)"
        }

        state = ProgressState(
            phase: phase,
            barProgress: highwaterProgress,
            barColor: barColor,
            questionLabel: questionLabel,
            tierDotColor: dotColor,
            timeEstimate: hardOverride || isComplete ? nil : timeEstimate,
            isHardOverride: hardOverride,
            isProcessing: false
        )
    }
}
