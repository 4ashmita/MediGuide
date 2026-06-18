import Foundation

enum PromptBuilder {

    private static let promptVersion = "1.0"

    static func build(userText: String, treeData: DecisionTreeData) -> ClaudeRequest {
        let sanitized = InputSanitizer.sanitize(userText)
        let system = assembleSystemPrompt(treeData: treeData)
        let user = "Analyze this text and extract symptoms:\n\n\(sanitized)"
        return .text(system: system, user: user)
    }

    // MARK: - Private

    private static func assembleSystemPrompt(treeData: DecisionTreeData) -> String {
        """
        \(SystemPromptTemplate.content)

        ---

        \(SymptomReferenceProvider.format(treeData: treeData))

        ---

        \(OutputSchemaDefinition.formatInstructions())

        ---

        \(PromptSafetyConstraints.content)

        ---

        EXAMPLES (prompt version \(promptVersion)):

        \(fewShotExamples)
        """
    }

    // Five examples covering: clear extraction, hard override, ambiguous/uncertain,
    // emotional content with no extractable symptoms, and PII in input.
    private static let fewShotExamples = """
    Example 1 — clear multi-symptom extraction:
    Input: "My 70-year-old dad fell and can't get up. He's confused and his lips look a little blue."
    Output:
    {
      "symptoms": ["fall_unable_to_get_up", "confusion", "blue_lips"],
      "modifiers": ["age_over_65"],
      "hard_override_detected": false,
      "uncertain": false,
      "summary": "Elderly person fell and is unable to get up, showing confusion and possible cyanosis."
    }

    Example 2 — hard override present:
    Input: "She stopped breathing and I can't wake her up."
    Output:
    {
      "symptoms": ["unconscious"],
      "modifiers": [],
      "hard_override_detected": true,
      "uncertain": false,
      "summary": "Person is unconscious and unresponsive."
    }

    Example 3 — ambiguous input, uncertain flagged:
    Input: "He just doesn't seem right today."
    Output:
    {
      "symptoms": [],
      "modifiers": ["instinct_override"],
      "hard_override_detected": false,
      "uncertain": true,
      "summary": "Caregiver reports a non-specific feeling that something is wrong without specific symptoms described."
    }

    Example 4 — emotional content, no extractable symptoms:
    Input: "I'm so scared and I don't know what to do. Please help me."
    Output:
    {
      "symptoms": [],
      "modifiers": [],
      "hard_override_detected": false,
      "uncertain": true,
      "summary": "Distress expressed without specific medical symptoms described."
    }

    Example 5 — PII present, extraction proceeds, PII excluded from summary:
    Input: "John Smith at 123 Main St, DOB 03/15/1958, has chest pain and can't breathe normally. His doctor is Dr. Lee."
    Output:
    {
      "symptoms": ["chest_pain", "difficulty_breathing"],
      "modifiers": [],
      "hard_override_detected": false,
      "uncertain": false,
      "summary": "Person is experiencing chest pain and difficulty breathing."
    }
    """
}
