import Foundation

struct ValidationRule {
    let field: ValidationField
    let severity: ValidationSeverity
    let errorMessage: String
    let validate: (UserProfile) -> Bool

    func check(profile: UserProfile) -> ValidationFailure? {
        guard !validate(profile) else { return nil }
        return ValidationFailure(field: field, message: errorMessage, severity: severity)
    }
}
