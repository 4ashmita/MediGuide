import Foundation

/// Central coordinator for all API response processing.
/// Every raw Claude response passes through here before any content-level parsing begins.
/// Performs sanity checks, schema validation, and routing — returning either a fully
/// parsed typed result or a classified failure. Never returns a partially processed response.
enum JSONResponseHandler {

    // MARK: - Text (NLP) responses

    /// Handles the full pipeline for a natural-language symptom extraction response.
    static func handleText(
        _ rawText: String,
        treeData: DecisionTreeData
    ) -> Result<LLMResponseParser.ParsedSymptoms, APIError> {
        // Step 1: Sanity check
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidResponse)
        }

        // Step 2: Parse to JSON dict for schema validation
        guard let json = parseJSON(rawText) else {
            APIUsageLogger.log(.failure(.invalidResponse))
            return .failure(.invalidResponse)
        }

        // Step 3: Schema validation — collects all violations before failing
        let violations = ResponseValidator.validateSchema(json, for: .text)
        if !violations.isEmpty {
            let reason = violations.map(\.description).joined(separator: "; ")
            let error = APIError.validationFailed(reason: "Schema violations: \(reason)")
            APIUsageLogger.log(.failure(error))
            return .failure(error)
        }

        // Step 4: Route to parser (parses JSON again internally; schema is already confirmed valid)
        return LLMResponseParser.parse(rawText, treeData: treeData)
    }

    // MARK: - Visual responses

    /// Handles the full pipeline for a vision photo analysis response.
    static func handleVisual(
        _ rawText: String,
        treeData: DecisionTreeData
    ) -> Result<VisualSymptomParser.ParsedVisualFindings, APIError> {
        // Step 1: Sanity check
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidResponse)
        }

        // Step 2: Parse to JSON dict for schema validation
        guard let json = parseJSON(rawText) else {
            APIUsageLogger.log(.failure(.invalidResponse))
            return .failure(.invalidResponse)
        }

        // Step 3: Schema validation
        let violations = ResponseValidator.validateSchema(json, for: .visual)
        if !violations.isEmpty {
            let reason = violations.map(\.description).joined(separator: "; ")
            let error = APIError.validationFailed(reason: "Schema violations: \(reason)")
            APIUsageLogger.log(.failure(error))
            return .failure(error)
        }

        // Step 4: Route to parser
        return VisualSymptomParser.parse(rawText, treeData: treeData)
    }

    // MARK: - Private

    /// Strips code fences and parses the response text to a JSON dictionary.
    private static func parseJSON(_ text: String) -> [String: Any]? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
