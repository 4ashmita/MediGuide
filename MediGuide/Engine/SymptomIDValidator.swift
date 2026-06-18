import Foundation

/// Validates that every symptom and modifier identifier in an API response exists in the
/// app's authoritative lists. Any unknown ID causes an immediate failure — there is no
/// partial-use path. If the proportion of unknown IDs is unusually high, the rejection
/// reason reflects the severity for better monitoring.
enum SymptomIDValidator {

    // Proportion of IDs that must be unknown before the error reason calls out "pollution".
    // The response is rejected regardless — this threshold only affects the logged reason.
    private static let pollutionThreshold: Double = 0.25

    // MARK: - Text response validation

    /// Validates symptom and modifier IDs from a text (NLP) response.
    static func validate(
        symptomIds: [String],
        modifierIds: [String],
        knownSymptoms: Set<String>,
        knownModifiers: Set<String>
    ) -> Result<Void, APIError> {
        let badSymptoms  = symptomIds.filter  { !knownSymptoms.contains($0) }
        let badModifiers = modifierIds.filter { !knownModifiers.contains($0) }
        let allBad = badSymptoms + badModifiers

        guard allBad.isEmpty else {
            let total = symptomIds.count + modifierIds.count
            let proportion = total > 0 ? Double(allBad.count) / Double(total) : 1.0
            let reason = proportion >= pollutionThreshold
                ? "ID pollution (\(Int(proportion * 100))% unknown): \(allBad)"
                : "Unknown IDs — symptoms: \(badSymptoms), modifiers: \(badModifiers)"
            APIUsageLogger.log(.failure(.validationFailed(reason: reason)))
            return .failure(.validationFailed(reason: reason))
        }

        return .success(())
    }

    // MARK: - Visual response validation

    /// Validates symptom IDs from a visual response (no modifiers in visual responses).
    static func validateVisualIds(_ ids: [String], knownSymptoms: Set<String>) -> Result<Void, APIError> {
        let bad = ids.filter { !knownSymptoms.contains($0) }

        guard bad.isEmpty else {
            let proportion = ids.isEmpty ? 1.0 : Double(bad.count) / Double(ids.count)
            let reason = proportion >= pollutionThreshold
                ? "Visual ID pollution (\(Int(proportion * 100))% unknown): \(bad)"
                : "Unknown visual symptom IDs: \(bad)"
            APIUsageLogger.log(.failure(.validationFailed(reason: reason)))
            return .failure(.validationFailed(reason: reason))
        }

        return .success(())
    }
}
