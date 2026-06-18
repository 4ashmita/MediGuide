import Foundation

enum ValidationField: Hashable {
    case displayName
    case dateOfBirth
    case trimester
    case emergencyContactName
    case emergencyContactPhone
    case emergencyContact
    case allergyEpiPen(String)
    case general
}

extension ValidationField {
    func appliesToStep(_ step: Int) -> Bool {
        switch self {
        case .displayName:
            return [1, 7].contains(step)
        case .dateOfBirth:
            return [2, 7].contains(step)
        case .trimester:
            return [3, 7].contains(step)
        case .emergencyContactName:
            return [6, 7].contains(step)
        case .emergencyContactPhone, .emergencyContact:
            return [6, 7].contains(step)
        case .allergyEpiPen:
            return [5, 7].contains(step)
        case .general:
            return step == 7
        }
    }
}

enum ValidationSeverity {
    case error
    case warning
}

struct ValidationFailure: Identifiable {
    let id = UUID()
    let field: ValidationField
    let message: String
    let severity: ValidationSeverity
}

struct ValidationResult {
    let failures: [ValidationFailure]

    var passed: Bool { failures.isEmpty }
    var errors: [ValidationFailure] { failures.filter { $0.severity == .error } }
    var warnings: [ValidationFailure] { failures.filter { $0.severity == .warning } }
    var hasErrors: Bool { !errors.isEmpty }
    var hasWarnings: Bool { !warnings.isEmpty }
}
