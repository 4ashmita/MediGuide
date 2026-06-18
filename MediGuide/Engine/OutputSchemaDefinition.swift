import Foundation

// Shared between PromptBuilder (to write instructions) and LLMResponseParser (to decode).
struct SymptomExtractionResult {
    let symptoms: [String]
    let modifiers: [String]
    let hardOverrideDetected: Bool
    let uncertain: Bool
    let summary: String
}

enum OutputSchemaDefinition {

    enum Fields {
        static let symptoms             = "symptoms"
        static let modifiers            = "modifiers"
        static let hardOverrideDetected = "hard_override_detected"
        static let uncertain            = "uncertain"
        static let summary              = "summary"
    }

    static func formatInstructions() -> String {
        """
        OUTPUT FORMAT:
        Respond with raw JSON only — no explanation, no markdown, no code fences.
        Use exactly these field names:

        {
          "\(Fields.symptoms)": ["symptom_id_here"],
          "\(Fields.modifiers)": ["modifier_id_here"],
          "\(Fields.hardOverrideDetected)": false,
          "\(Fields.uncertain)": false,
          "\(Fields.summary)": "One or two sentences describing what was observed."
        }

        Field rules:
        - "\(Fields.symptoms)": IDs from the SYMPTOMS list only. Empty array [] if none apply.
        - "\(Fields.modifiers)": IDs from the MODIFIERS list only. Empty array [] if none apply.
        - "\(Fields.hardOverrideDetected)": true if any identified symptom appears in the HARD OVERRIDE list.
        - "\(Fields.uncertain)": true when the input is too vague to extract anything reliably.
        - "\(Fields.summary)": Plain-language description of what was observed. Never include names, ages, dates, locations, or any identifying information.
        """
    }
}
