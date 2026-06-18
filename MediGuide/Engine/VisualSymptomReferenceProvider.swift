import Foundation

enum VisualSymptomReferenceProvider {

    // Symptoms from the decision tree that have a meaningful visual presentation in a photo.
    // Symptoms requiring verbal report (confusion, chest pain, difficulty breathing, etc.)
    // are intentionally excluded — including them risks encouraging visual inference of
    // things that cannot actually be seen.
    static let visualSymptomIds: Set<String> = [
        "blue_lips",
        "fall_with_injury",
        "hives_sudden",
        "new_weakness_one_side",
        "rash_with_fever_child",
        "severe_allergic_reaction",
        "severe_bleeding",
        "soft_spot_bulging",
        "stroke_symptoms",
        "swelling_sudden",
        "throat_tightening",
    ]

    /// Plain-language description of a visual symptom ID for UI display.
    static func description(for id: String) -> String {
        visualDescriptions[id] ?? id.replacingOccurrences(of: "_", with: " ").capitalized
    }

    static func format(treeData: DecisionTreeData) -> String {
        let hardOverrides = Set(treeData.hardOverrides)

        let lines = visualSymptomIds
            .filter { treeData.symptomWeights[$0] != nil }
            .sorted()
            .map { id -> String in
                let desc = visualDescriptions[id] ?? id.replacingOccurrences(of: "_", with: " ")
                let flag = hardOverrides.contains(id) ? " ⚠️ HARD OVERRIDE" : ""
                return "- \(id): \(desc)\(flag)"
            }
            .joined(separator: "\n")

        return """
        VISUALLY OBSERVABLE SYMPTOMS — use only these exact IDs:
        \(lines)

        Do not use any symptom identifier not listed above, even if the full triage symptom \
        list contains others. This list contains only symptoms that can be meaningfully \
        assessed from a photograph.
        """
    }

    // Descriptions written for visual recognition rather than verbal description
    private static let visualDescriptions: [String: String] = [
        "blue_lips":              "Blue, purple, or grayish discoloration of the lips or skin surface",
        "fall_with_injury":       "Visible wound, laceration, bruising, deformity, or swelling following a fall",
        "hives_sudden":           "Raised red or skin-colored welts, hives, or blotchy rash patches on the skin",
        "new_weakness_one_side":  "Visible drooping or asymmetry affecting one side of the face",
        "rash_with_fever_child":  "Spots, blotches, or skin discoloration visible on a child's skin",
        "severe_allergic_reaction": "Widespread hives or visible swelling of the face, lips, or throat area",
        "severe_bleeding":        "Active bleeding, blood-saturated wound, or significant visible blood",
        "soft_spot_bulging":      "The soft spot on an infant's head visibly bulging or pushing outward",
        "stroke_symptoms":        "Facial drooping or asymmetry, particularly one side of the face not moving normally",
        "swelling_sudden":        "Visible swelling, puffiness, or enlargement of a limb, joint, or facial area",
        "throat_tightening":      "Visible swelling or distension of the neck or throat region",
    ]
}
