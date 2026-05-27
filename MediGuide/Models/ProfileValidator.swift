import Foundation

enum ProfileValidationError: LocalizedError {
    case displayNameEmpty
    case dateOfBirthInFuture
    case dateOfBirthImpossible
    case emergencyPhoneInvalid

    var errorDescription: String? {
        switch self {
        case .displayNameEmpty:
            return "Please enter a name for this profile."
        case .dateOfBirthInFuture:
            return "Date of birth must be in the past."
        case .dateOfBirthImpossible:
            return "Please enter a valid date of birth."
        case .emergencyPhoneInvalid:
            return "Please enter a valid phone number for the emergency contact."
        }
    }
}

enum ProfileValidator {

    static func validate(_ profile: UserProfile) -> ProfileValidationError? {
        if profile.displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            return .displayNameEmpty
        }
        if profile.dateOfBirth >= Date() {
            return .dateOfBirthInFuture
        }
        let age = Calendar.current.dateComponents([.year], from: profile.dateOfBirth, to: Date()).year ?? 0
        if age > 120 {
            return .dateOfBirthImpossible
        }
        if !profile.emergencyContactPhone.isEmpty && !isValidPhone(profile.emergencyContactPhone) {
            return .emergencyPhoneInvalid
        }
        return nil
    }

    static func isStepValid(step: Int, profile: UserProfile) -> Bool {
        switch step {
        case 1: return !profile.displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return profile.dateOfBirth < Date()
        case 3, 4, 5: return true
        case 6: return profile.emergencyContactPhone.isEmpty || isValidPhone(profile.emergencyContactPhone)
        default: return true
        }
    }

    private static func isValidPhone(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 10 && digits.count <= 15
    }
}
