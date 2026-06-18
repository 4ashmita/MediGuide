import Foundation

enum LLMResponseParser {

    struct ParsedSymptoms {
        let symptoms: [Symptom]
        let modifiers: [Modifier]
        let hardOverrideDetected: Bool
        let uncertain: Bool
        let summary: String
    }

    /// Full pipeline: parse JSON → validate schema → validate identifiers → map to engine types.
    static func parse(_ jsonText: String, treeData: DecisionTreeData) -> Result<ParsedSymptoms, APIError> {
        guard let raw = decodeJSON(jsonText) else {
            return .failure(.invalidResponse)
        }

        let knownSymptoms  = Set(treeData.symptomWeights.keys)
        let knownModifiers = Set(treeData.modifierWeights.keys)

        switch SymptomIDValidator.validate(
            symptomIds: raw.symptoms,
            modifierIds: raw.modifiers,
            knownSymptoms: knownSymptoms,
            knownModifiers: knownModifiers
        ) {
        case .failure(let error): return .failure(error)
        case .success: break
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
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let f = OutputSchemaDefinition.Fields.self
        return SymptomExtractionResult(
            symptoms:             FieldExtractor.optionalStringArray(f.symptoms,  from: json),
            modifiers:            FieldExtractor.optionalStringArray(f.modifiers, from: json),
            hardOverrideDetected: FieldExtractor.optionalBool(f.hardOverrideDetected, from: json),
            uncertain:            FieldExtractor.optionalBool(f.uncertain,            from: json),
            summary:              ResponseSanitizer.sanitize(
                                      FieldExtractor.optionalString(f.summary, from: json))
        )
    }
}
