import Foundation

enum WakeContext: String, Hashable {
    case emergencyCountdown
    case activeCall
    case call911Recommendation
    case goToERRecommendation
    case urgentCareRecommendation
    case firstAidGuidance
}

@MainActor
final class WakeContextRegistry {
    static let shared = WakeContextRegistry()
    private init() {}

    private(set) var activeContexts = Set<WakeContext>()

    var hasActiveContexts: Bool { !activeContexts.isEmpty }

    func register(_ context: WakeContext) {
        let wasEmpty = activeContexts.isEmpty
        activeContexts.insert(context)
        if wasEmpty {
            ScreenWakeManager.shared.engage()
        }
        BrightnessController.shared.evaluate(activeContexts: activeContexts)
    }

    func release(_ context: WakeContext) {
        activeContexts.remove(context)
        BrightnessController.shared.evaluate(activeContexts: activeContexts)
        if activeContexts.isEmpty {
            ScreenWakeManager.shared.disengage()
        }
    }
}
