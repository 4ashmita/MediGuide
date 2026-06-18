import Foundation

enum ResponseValidator {

    // MARK: - Claude envelope extraction

    private struct ClaudeEnvelope: Decodable {
        let content: [Block]
        let stopReason: String?
        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }
        struct Block: Decodable { let type: String; let text: String? }
    }

    /// Validates the outer Claude API envelope and returns the assistant's text content.
    static func extractText(from data: Data) -> Result<String, APIError> {
        guard let envelope = try? JSONDecoder().decode(ClaudeEnvelope.self, from: data),
              let text = envelope.content.first(where: { $0.type == "text" })?.text,
              !text.isEmpty
        else { return .failure(.invalidResponse) }
        return .success(text)
    }

    // MARK: - Schema validation

    enum CallType { case text, visual }

    /// Structural schema check for a pre-parsed JSON dictionary.
    /// Returns every violation found — not just the first — for better observability.
    static func validateSchema(_ json: [String: Any], for callType: CallType) -> [SchemaViolation] {
        switch callType {
        case .text:   return SchemaEnforcer.validateText(json)
        case .visual: return SchemaEnforcer.validateVisual(json)
        }
    }

    // MARK: - Response error classification

    enum ResponseErrorCategory {
        case parseFailed
        case schemaViolation([SchemaViolation])
        case identifierPollution(invalidIds: [String])
        case uncertainResponse
        case lowConfidenceOnly
    }

    static func classify(apiError: APIError) -> ResponseErrorCategory {
        switch apiError {
        case .invalidResponse:
            return .parseFailed
        case .validationFailed(let reason):
            if reason.contains("pollution") { return .identifierPollution(invalidIds: []) }
            return .schemaViolation([])
        default:
            return .parseFailed
        }
    }

    // MARK: - SchemaViolation

    struct SchemaViolation: CustomStringConvertible {
        let field: String
        let reason: String
        var description: String { "'\(field)': \(reason)" }
    }

    // MARK: - SchemaEnforcer (private)

    private enum SchemaEnforcer {

        static func validateText(_ json: [String: Any]) -> [SchemaViolation] {
            var v: [SchemaViolation] = []
            checkStringArray(OutputSchemaDefinition.Fields.symptoms,  in: json, into: &v)
            checkStringArray(OutputSchemaDefinition.Fields.modifiers,  in: json, into: &v)
            checkBool(OutputSchemaDefinition.Fields.hardOverrideDetected, in: json, into: &v)
            checkBool(OutputSchemaDefinition.Fields.uncertain,            in: json, into: &v)
            // summary is optional; if present it must be a string
            if let raw = json[OutputSchemaDefinition.Fields.summary], !(raw is String) {
                v.append(SchemaViolation(field: OutputSchemaDefinition.Fields.summary, reason: "must be string"))
            }
            return v
        }

        static func validateVisual(_ json: [String: Any]) -> [SchemaViolation] {
            var v: [SchemaViolation] = []
            let f = VisualOutputSchemaDefinition.Fields.self

            // findings — required array of objects with required sub-fields
            if let raw = json[f.findings] {
                if let arr = raw as? [[String: Any]] {
                    for (i, item) in arr.enumerated() {
                        if !(item[f.symptomId] is String) {
                            v.append(SchemaViolation(field: "findings[\(i)].symptom_id", reason: "missing or not a string"))
                        }
                        if let conf = item[f.confidence] as? String {
                            if VisualExtractionResult.Finding.Confidence(rawValue: conf) == nil {
                                v.append(SchemaViolation(field: "findings[\(i)].confidence",
                                                         reason: "unrecognized value '\(conf)' — expected high|medium|low"))
                            }
                        } else {
                            v.append(SchemaViolation(field: "findings[\(i)].confidence", reason: "missing or not a string"))
                        }
                        if !(item[f.plainDescription] is String) {
                            v.append(SchemaViolation(field: "findings[\(i)].plain_description", reason: "missing or not a string"))
                        }
                    }
                } else {
                    v.append(SchemaViolation(field: f.findings, reason: "must be array of objects"))
                }
            } else {
                v.append(SchemaViolation(field: f.findings, reason: "missing required field"))
            }

            // image_quality — optional but must be a recognized value if present
            if let raw = json[f.imageQuality] {
                if let str = raw as? String {
                    if VisualExtractionResult.ImageQuality(rawValue: str) == nil {
                        v.append(SchemaViolation(field: f.imageQuality,
                                                 reason: "unrecognized value '\(str)' — expected good|fair|poor"))
                    }
                } else {
                    v.append(SchemaViolation(field: f.imageQuality, reason: "must be string"))
                }
            }

            // has_concerning_pattern — optional bool
            if let raw = json[f.hasConcerningPattern], !(raw is Bool) {
                v.append(SchemaViolation(field: f.hasConcerningPattern, reason: "must be bool"))
            }

            // uncertain — optional bool
            if let raw = json[f.uncertain], !(raw is Bool) {
                v.append(SchemaViolation(field: f.uncertain, reason: "must be bool"))
            }

            return v
        }

        // MARK: - Helpers

        private static func checkStringArray(_ key: String, in json: [String: Any], into v: inout [SchemaViolation]) {
            if let raw = json[key] {
                if !(raw is [String]) {
                    v.append(SchemaViolation(field: key, reason: "must be array of strings"))
                }
            } else {
                v.append(SchemaViolation(field: key, reason: "missing required field"))
            }
        }

        private static func checkBool(_ key: String, in json: [String: Any], into v: inout [SchemaViolation]) {
            if let raw = json[key] {
                if !(raw is Bool) {
                    v.append(SchemaViolation(field: key, reason: "must be bool"))
                }
            } else {
                v.append(SchemaViolation(field: key, reason: "missing required field"))
            }
        }
    }
}
