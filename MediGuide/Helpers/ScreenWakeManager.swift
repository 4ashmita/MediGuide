import UIKit

@MainActor
final class ScreenWakeManager {
    static let shared = ScreenWakeManager()
    private init() {}

    func engage() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func disengage() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
