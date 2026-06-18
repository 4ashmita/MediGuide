import Foundation

enum OnboardingManager {

    static var hasCompletedSetup: Bool {
        UserDefaults.standard.bool(forKey: StorageKeys.Defaults.profileCreated)
    }

    static var hasPermanentlySkipped: Bool {
        UserDefaults.standard.bool(forKey: StorageKeys.Defaults.permanentlySkipped)
    }

    static func markProfileCreated() {
        UserDefaults.standard.set(true, forKey: StorageKeys.Defaults.profileCreated)
    }

    static func resetProfileCreated() {
        UserDefaults.standard.set(false, forKey: StorageKeys.Defaults.profileCreated)
    }

    static func markPermanentlySkipped() {
        UserDefaults.standard.set(true, forKey: StorageKeys.Defaults.permanentlySkipped)
    }

    // Returns true if the creation screen should be shown on launch
    static func shouldShowCreation() -> Bool {
        !hasCompletedSetup && !hasPermanentlySkipped
    }
}
