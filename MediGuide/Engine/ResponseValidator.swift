import Foundation

enum ResponseValidator {

    private struct ClaudeEnvelope: Decodable {
        let content: [Block]
        let stopReason: String?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }

        struct Block: Decodable {
            let type: String
            let text: String?
        }
    }

    /// Validates the outer Claude API envelope and returns the assistant's text content.
    static func extractText(from data: Data) -> Result<String, APIError> {
        guard let envelope = try? JSONDecoder().decode(ClaudeEnvelope.self, from: data),
              let text = envelope.content.first(where: { $0.type == "text" })?.text,
              !text.isEmpty else {
            return .failure(.invalidResponse)
        }
        return .success(text)
    }

    /// Parses a structured JSON text response and validates every identifier against the known sets.
    /// Unknown identifiers are rejected; only verified IDs are returned.
    static func validateIdentifiers(
        in jsonText: String,
        symptomKey: String = "symptoms",
        modifierKey: String = "modifiers",
        knownSymptoms: Set<String>,
        knownModifiers: Set<String>
    ) -> Result<(symptoms: [String], modifiers: [String]), APIError> {
        guard let data = jsonText.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(.validationFailed(reason: "Response is not valid JSON"))
        }

        let rawSymptoms  = json[symptomKey]  as? [String] ?? []
        let rawModifiers = json[modifierKey] as? [String] ?? []

        let badSymptoms  = rawSymptoms.filter  { !knownSymptoms.contains($0) }
        let badModifiers = rawModifiers.filter { !knownModifiers.contains($0) }

        guard badSymptoms.isEmpty && badModifiers.isEmpty else {
            return .failure(.validationFailed(
                reason: "Unknown IDs — symptoms: \(badSymptoms), modifiers: \(badModifiers)"
            ))
        }

        return .success((symptoms: rawSymptoms, modifiers: rawModifiers))
    }
}
