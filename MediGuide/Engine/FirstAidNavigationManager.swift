import Foundation
import Combine

final class FirstAidNavigationManager: ObservableObject {

    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var isComplete: Bool = false

    private(set) var steps: [FirstAidStep] = []

    var currentStep: FirstAidStep? {
        steps.indices.contains(currentStepIndex) ? steps[currentStepIndex] : nil
    }
    var totalSteps: Int { steps.count }
    var canGoBack: Bool { currentStepIndex > 0 }
    var isLastStep: Bool { currentStepIndex >= steps.count - 1 }
    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps)
    }

    func load(steps: [FirstAidStep]) {
        self.steps = steps
        currentStepIndex = 0
        isComplete = false
    }

    func advance() {
        guard !isLastStep else { isComplete = true; return }
        currentStepIndex += 1
    }

    func goBack() {
        guard canGoBack else { return }
        currentStepIndex -= 1
        isComplete = false
    }

    func reset() {
        currentStepIndex = 0
        isComplete = false
    }
}
