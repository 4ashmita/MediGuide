import UIKit

@MainActor
final class BrightnessController {
    static let shared = BrightnessController()
    private init() {}

    private var savedBrightness: CGFloat = -1
    private var isPaused = false

    func evaluate(activeContexts: Set<WakeContext>) {
        guard !isPaused else { return }
        if let target = targetBrightness(for: activeContexts) {
            let current = UIScreen.main.brightness
            guard current < target else { return }
            if savedBrightness < 0 { savedBrightness = current }
            UIScreen.main.brightness = target
        } else {
            restore()
        }
    }

    func pause() {
        isPaused = true
    }

    func resume(activeContexts: Set<WakeContext>) {
        isPaused = false
        evaluate(activeContexts: activeContexts)
    }

    private func restore() {
        guard savedBrightness >= 0 else { return }
        UIScreen.main.brightness = savedBrightness
        savedBrightness = -1
    }

    private func targetBrightness(for contexts: Set<WakeContext>) -> CGFloat? {
        if contexts.contains(.emergencyCountdown) || contexts.contains(.activeCall) {
            return 1.0
        }
        if contexts.contains(.goToERRecommendation) {
            return 0.85
        }
        return nil
    }
}
