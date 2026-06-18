import Foundation

enum ProfileValidator {

    private static let rules: [ValidationRule] = [
        // Display Name
        ValidationRule(
            field: .displayName,
            severity: .error,
            errorMessage: "Please enter a name for this profile.",
            validate: { FieldValidator.isNotEmpty($0.displayName) }
        ),
        ValidationRule(
            field: .displayName,
            severity: .error,
            errorMessage: "Name must contain at least one letter.",
            validate: { profile in
                guard FieldValidator.isNotEmpty(profile.displayName) else { return true }
                return FieldValidator.isValidName(profile.displayName)
            }
        ),
        ValidationRule(
            field: .displayName,
            severity: .error,
            errorMessage: "Name must be 50 characters or fewer.",
            validate: { FieldValidator.isWithinLength($0.displayName, max: 50) }
        ),
        // Date of Birth
        ValidationRule(
            field: .dateOfBirth,
            severity: .error,
            errorMessage: "Date of birth must be in the past.",
            validate: { FieldValidator.isDateInPast($0.dateOfBirth) }
        ),
        ValidationRule(
            field: .dateOfBirth,
            severity: .error,
            errorMessage: "Please enter a valid date of birth.",
            validate: { FieldValidator.isAgeInValidRange($0.dateOfBirth) }
        ),
        // Emergency Contact Phone
        ValidationRule(
            field: .emergencyContactPhone,
            severity: .error,
            errorMessage: "Please enter a valid phone number (at least 10 digits).",
            validate: { profile in
                guard !profile.emergencyContactPhone.isEmpty else { return true }
                return FieldValidator.isValidPhone(profile.emergencyContactPhone)
            }
        ),
        // Emergency Contact Consistency Warnings
        ValidationRule(
            field: .emergencyContact,
            severity: .warning,
            errorMessage: "Emergency contact name is missing. Add a name so responders know who to call.",
            validate: { profile in
                guard !profile.emergencyContactPhone.isEmpty else { return true }
                return FieldValidator.isNotEmpty(profile.emergencyContactName)
            }
        ),
        ValidationRule(
            field: .emergencyContact,
            severity: .warning,
            errorMessage: "Emergency contact phone number is missing. Add a number to enable automatic SMS alerts.",
            validate: { profile in
                guard FieldValidator.isNotEmpty(profile.emergencyContactName) else { return true }
                return !profile.emergencyContactPhone.isEmpty
            }
        ),
    ]

    // MARK: - Full Validation

    static func validate(profile: UserProfile) -> ValidationResult {
        var failures = rules.compactMap { $0.check(profile: profile) }
        for allergy in profile.allergies where allergy.severity >= .severe && !allergy.carriesEpiPen {
            failures.append(ValidationFailure(
                field: .allergyEpiPen(allergy.allergen),
                message: "\(allergy.allergen) is \(allergy.severity.displayName.lowercased()) — note if an EpiPen is carried.",
                severity: .warning
            ))
        }
        return ValidationResult(failures: failures)
    }

    // MARK: - Step Validation

    static func validate(step: Int, profile: UserProfile) -> ValidationResult {
        let all = validate(profile: profile)
        return ValidationResult(failures: all.failures.filter { $0.field.appliesToStep(step) })
    }

    static func isStepValid(step: Int, profile: UserProfile) -> Bool {
        !validate(step: step, profile: profile).hasErrors
    }

    // MARK: - Trimester (VM-level — cannot be derived from UserProfile alone)

    static func validateTrimester(pregnancyOn: Bool, trimestedId: String?) -> ValidationFailure? {
        guard pregnancyOn, trimestedId == nil else { return nil }
        return ValidationFailure(
            field: .trimester,
            message: "Please select a trimester or stage.",
            severity: .error
        )
    }

    // MARK: - Real-time Helpers

    static func validateDisplayName(_ name: String) -> ValidationFailure? {
        let nameRules = rules.filter { $0.field == .displayName }
        let dummy = UserProfile(
            displayName: name,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
            biologicalSex: .preferNotToSay
        )
        return nameRules.compactMap { $0.check(profile: dummy) }.first
    }

    static func validatePhone(_ phone: String) -> ValidationFailure? {
        guard !phone.isEmpty else { return nil }
        if !FieldValidator.containsOnlyValidPhoneChars(phone) {
            return ValidationFailure(
                field: .emergencyContactPhone,
                message: "Phone number contains invalid characters.",
                severity: .error
            )
        }
        if !FieldValidator.hasValidDigitCount(phone) {
            return ValidationFailure(
                field: .emergencyContactPhone,
                message: "Please enter a valid phone number (at least 10 digits).",
                severity: .error
            )
        }
        return nil
    }
}
