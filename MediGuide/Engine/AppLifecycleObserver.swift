import Foundation

@MainActor
enum AppLifecycleObserver {
    static func handleBackground() {
        BrightnessController.shared.pause()
    }

    static func handleForeground() {
        let registry = WakeContextRegistry.shared
        BrightnessController.shared.resume(activeContexts: registry.activeContexts)
        if registry.hasActiveContexts {
            ScreenWakeManager.shared.engage()
        }
    }
}
