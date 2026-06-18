import Foundation
import LocalAuthentication

enum BiometricAuthManager {

    // MARK: - Available type

    enum AuthType {
        case faceID, touchID, passcode, none

        var buttonLabel: String {
            switch self {
            case .faceID:   return "Use Face ID"
            case .touchID:  return "Use Touch ID"
            case .passcode: return "Enter Passcode"
            case .none:     return "Authenticate"
            }
        }

        var systemImage: String {
            switch self {
            case .faceID:   return "faceid"
            case .touchID:  return "touchid"
            case .passcode: return "lock.fill"
            case .none:     return "lock.fill"
            }
        }
    }

    static var availableType: AuthType {
        let ctx = LAContext()
        var error: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return ctx.biometryType == .faceID ? .faceID : .touchID
        }
        if ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return .passcode
        }
        return .none
    }

    static var isBiometricsEnrolled: Bool {
        let ctx = LAContext()
        var error: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // MARK: - Reason strings

    enum Reason {
        case loadProfile, manageProfiles, viewMedicalInfo, enableProtection, disableProtection

        var string: String {
            switch self {
            case .loadProfile:        return "Authenticate to load health profile for triage"
            case .manageProfiles:     return "Authenticate to view and edit health profiles"
            case .viewMedicalInfo:    return "Authenticate to view medical information"
            case .enableProtection:   return "Authenticate to enable profile privacy protection"
            case .disableProtection:  return "Authenticate to disable profile privacy protection"
            }
        }
    }

    // MARK: - Authenticate

    enum AuthResult {
        case success, failure(String), cancelled, unavailable
    }

    static func authenticate(reason: Reason, allowPasscodeFallback: Bool = true) async -> AuthResult {
        let policy: LAPolicy = allowPasscodeFallback
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics

        let ctx = LAContext()
        var canError: NSError?
        guard ctx.canEvaluatePolicy(policy, error: &canError) else {
            return .unavailable
        }

        do {
            let success = try await ctx.evaluatePolicy(policy, localizedReason: reason.string)
            return success ? .success : .failure("Authentication failed.")
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .cancelled
            case .biometryNotEnrolled, .passcodeNotSet:
                return .unavailable
            default:
                return .failure(laError.localizedDescription)
            }
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
