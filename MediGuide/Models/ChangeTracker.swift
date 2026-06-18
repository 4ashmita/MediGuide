import Foundation

final class ChangeTracker {

    private let original: UserProfile

    init(original: UserProfile) {
        self.original = original
    }

    var hasChanges: Bool {
        !changedFields.isEmpty
    }

    private(set) var changedFields: Set<String> = []

    func track<T: Equatable>(_ field: String, current: T) {
        let originalValue = value(for: field)
        if let originalValue = originalValue as? T, originalValue != current {
            changedFields.insert(field)
        } else if originalValue == nil {
            changedFields.insert(field)
        } else {
            changedFields.remove(field)
        }
    }

    private func value(for field: String) -> Any? {
        switch field {
        case "displayName":            return original.displayName
        case "dateOfBirth":            return original.dateOfBirth
        case "biologicalSex":          return original.biologicalSex
        case "bloodType":              return original.bloodType
        case "conditions":             return original.conditions
        case "conditionOtherNote":     return original.conditionOtherNote
        case "medications":            return original.medications
        case "allergies":              return original.allergies
        case "emergencyContactName":   return original.emergencyContactName
        case "emergencyContactPhone":  return original.emergencyContactPhone
        default:                       return nil
        }
    }
}
