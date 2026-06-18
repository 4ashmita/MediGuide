import Foundation

enum LLMResponseParser {

    struct ParsedSymptoms {
        let symptoms: [Symptom]
        let modifiers: [Modifier]
        let hardOverrideDetected: Bool
        let uncertain: Bool
        let summary: String
    }

    /// Full pipeline: parse JSON → validate identifiers → map to engine types.
    static func parse(_ jsonText: String, treeData: DecisionTreeData) -> Result<ParsedSymptoms, APIError> {
        guard let raw = decodeJSON(jsonText) else {
            return .failure(.invalidResponse)
        }

        let knownSymptoms  = Set(treeData.symptomWeights.keys)
        let knownModifiers = Set(treeData.modifierWeights.keys)

        let unknownSymptoms  = raw.symptoms.filter  { !knownSymptoms.contains($0) }
        let unknownModifiers = raw.modifiers.filter { !knownModifiers.contains($0) }

        guard unknownSymptoms.isEmpty && unknownModifiers.isEmpty else {
            return .failure(.validationFailed(
                reason: "Unknown IDs — symptoms: \(unknownSymptoms), modifiers: \(unknownModifiers)"
            ))
        }

        let symptoms = raw.symptoms.compactMap { id -> Symptom? in
            guard let weight = treeData.symptomWeights[id] else { return nil }
            return Symptom(symptomId: id, weight: weight)
        }
        let modifiers = raw.modifiers.compactMap { id -> Modifier? in
            guard let weight = treeData.modifierWeights[id] else { return nil }
            return Modifier(modifierId: id, weight: weight)
        }

        return .success(ParsedSymptoms(
            symptoms: symptoms,
            modifiers: modifiers,
            hardOverrideDetected: raw.hardOverrideDetected,
            uncertain: raw.uncertain,
            summary: raw.summary
        ))
    }

    // MARK: - Private

    private static func decodeJSON(_ text: String) -> SymptomExtractionResult? {
        // Claude sometimes wraps output in a code fence even when told not to — strip it
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return SymptomExtractionResult(
            symptoms:             json[OutputSchemaDefinition.Fields.symptoms]             as? [String] ?? [],
            modifiers:            json[OutputSchemaDefinition.Fields.modifiers]            as? [String] ?? [],
            hardOverrideDetected: json[OutputSchemaDefinition.Fields.hardOverrideDetected] as? Bool ?? false,
            uncertain:            json[OutputSchemaDefinition.Fields.uncertain]            as? Bool ?? false,
            summary:              json[OutputSchemaDefinition.Fields.summary]              as? String ?? ""
        )
    }
}
