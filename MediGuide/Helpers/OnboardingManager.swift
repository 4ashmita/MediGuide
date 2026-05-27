import Foundation

enum OnboardingManager {

    private static let profileCreatedKey = "mediguide.profileCreated"
    private static let permanentlySkippedKey = "mediguide.onboardingSkipped"

    static var hasCompletedSetup: Bool {
        UserDefaults.standard.bool(forKey: profileCreatedKey)
    }

    static var hasPermanentlySkipped: Bool {
        UserDefaults.standard.bool(forKey: permanentlySkippedKey)
    }

    static func markProfileCreated() {
        UserDefaults.standard.set(true, forKey: profileCreatedKey)
    }

    static func resetProfileCreated() {
        UserDefaults.standard.set(false, forKey: profileCreatedKey)
    }

    static func markPermanentlySkipped() {
        UserDefaults.standard.set(true, forKey: permanentlySkippedKey)
    }

    // Returns true if the creation screen should be shown on launch
    static func shouldShowCreation() -> Bool {
        !hasCompletedSetup && !hasPermanentlySkipped
    }
}
