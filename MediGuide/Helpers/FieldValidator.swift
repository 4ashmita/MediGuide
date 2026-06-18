import Foundation

enum FieldValidator {

    static func isNotEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func isWithinLength(_ value: String, max: Int) -> Bool {
        value.trimmingCharacters(in: .whitespaces).count <= max
    }

    static func isValidName(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespaces).contains(where: { $0.isLetter })
    }

    static func isDateInPast(_ date: Date) -> Bool {
        date < Date()
    }

    static func isAgeInValidRange(_ date: Date, maxYears: Int = 120) -> Bool {
        let age = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        return age <= maxYears
    }

    static func containsOnlyValidPhoneChars(_ phone: String) -> Bool {
        phone.allSatisfy { $0.isNumber || "+(). -".contains($0) }
    }

    static func hasValidDigitCount(_ phone: String, min: Int = 10, max: Int = 15) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= min && digits.count <= max
    }

    static func isValidPhone(_ phone: String) -> Bool {
        guard !phone.isEmpty else { return false }
        return containsOnlyValidPhoneChars(phone) && hasValidDigitCount(phone)
    }
}
