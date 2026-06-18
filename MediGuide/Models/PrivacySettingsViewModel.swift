import Foundation
import Combine

@MainActor
final class PrivacySettingsViewModel: ObservableObject {

    @Published var isEnabled: Bool = false
    @Published var windowMinutes: Int = 5
    @Published var lockOnBackground: Bool = true
    @Published var passcodeFallback: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil

    // Authentication window options shown in the UI
    let windowOptions: [(label: String, minutes: Int)] = [
        ("1 minute",          1),
        ("5 minutes",         5),
        ("15 minutes",       15),
        ("Until app closes", Int.max)
    ]

    var biometricType: BiometricAuthManager.AuthType { BiometricAuthManager.availableType }
    var isBiometricsEnrolled: Bool { BiometricAuthManager.isBiometricsEnrolled }

    func load() {
        let ud = UserDefaults.standard
        isEnabled        = ud.bool(forKey: StorageKeys.Defaults.privacyEnabled)
        passcodeFallback = ud.object(forKey: StorageKeys.Defaults.privacyPasscodeFallback) == nil
            ? true
            : ud.bool(forKey: StorageKeys.Defaults.privacyPasscodeFallback)
        let raw = ud.integer(forKey: StorageKeys.Defaults.privacyWindowMinutes)
        windowMinutes = raw > 0 ? raw : 5
        let bgKey = StorageKeys.Defaults.privacyLockOnBackground
        lockOnBackground = ud.object(forKey: bgKey) == nil ? true : ud.bool(forKey: bgKey)
    }

    // MARK: - Toggle Protection

    func setEnabled(_ newValue: Bool) {
        Task {
            isLoading = true
            errorMessage = nil
            let reason: BiometricAuthManager.Reason = newValue ? .enableProtection : .disableProtection
            let result = await BiometricAuthManager.authenticate(reason: reason,
                                                                 allowPasscodeFallback: passcodeFallback)
            isLoading = false
            switch result {
            case .success:
                saveEnabled(newValue)
                reconfigureKeychain(biometricProtected: newValue)
                if !newValue { AuthStateManager.shared.lock() }
                successMessage = newValue ? "Profiles protected" : "Protection disabled"
            case .failure(let msg):
                errorMessage = msg
            case .cancelled:
                break
            case .unavailable:
                errorMessage = "Biometrics unavailable. Set up Face ID or a passcode in device Settings."
            }
        }
    }

    private func saveEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: StorageKeys.Defaults.privacyEnabled)
    }

    // MARK: - Window Duration

    func setWindow(minutes: Int) {
        windowMinutes = minutes
        UserDefaults.standard.set(minutes, forKey: StorageKeys.Defaults.privacyWindowMinutes)
    }

    // MARK: - Background Lock

    func setLockOnBackground(_ value: Bool) {
        lockOnBackground = value
        UserDefaults.standard.set(value, forKey: StorageKeys.Defaults.privacyLockOnBackground)
    }

    // MARK: - Passcode Fallback

    func setPasscodeFallback(_ value: Bool) {
        passcodeFallback = value
        UserDefaults.standard.set(value, forKey: StorageKeys.Defaults.privacyPasscodeFallback)
    }

    // MARK: - Keychain Reconfiguration

    private func reconfigureKeychain(biometricProtected: Bool) {
        let ids = ProfileRepository.summaries().map(\.id)
        for id in ids {
            let sensitiveKey  = StorageKeys.Keychain.sensitiveData(for: id)
            let medKey        = StorageKeys.Keychain.medications(for: id)
            let allergyKey    = StorageKeys.Keychain.allergies(for: id)
            if biometricProtected {
                KeychainManager.reconfigureToBiometricProtected(key: sensitiveKey)
                KeychainManager.reconfigureToBiometricProtected(key: medKey)
                KeychainManager.reconfigureToBiometricProtected(key: allergyKey)
            } else {
                KeychainManager.reconfigureToStandard(key: sensitiveKey)
                KeychainManager.reconfigureToStandard(key: medKey)
                KeychainManager.reconfigureToStandard(key: allergyKey)
            }
        }
    }
}
