import Foundation

/// A finding produced by a domain analyzer after applying clinical calibration rules.
/// Confidence may be raised from the raw Claude output; `isHardEscalation` bypasses the
/// normal low-confidence filter in the aggregator.
struct CalibratedFinding {
    let symptomId: String
    let originalFinding: VisualExtractionResult.Finding
    let calibratedConfidence: VisualExtractionResult.Finding.Confidence
    let clinicalNote: String?
    let isHardEscalation: Bool
}

struct VisualExtractionResult {
    struct Finding {
        let symptomId: String
        let confidence: Confidence
        let plainDescription: String

        enum Confidence: String {
            case high, medium, low
        }
    }

    enum ImageQuality: String {
        case good, fair, poor
    }

    let findings: [Finding]
    let imageQuality: ImageQuality
    let hasConcerningPattern: Bool
    let uncertain: Bool
}

/// Converts a raw confidence string from a Claude response to the internal Confidence enum.
/// Unrecognized values fall back to .low (conservative default).
/// Poor-quality images cap findings at .medium — a poor photo cannot produce high confidence.
enum ConfidenceLevelMapper {
    static func map(
        _ rawValue: String,
        imageQuality: VisualExtractionResult.ImageQuality = .good
    ) -> VisualExtractionResult.Finding.Confidence {
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = VisualExtractionResult.Finding.Confidence(rawValue: normalized) ?? .low
        if imageQuality == .poor && base == .high { return .medium }
        return base
    }
}

enum VisualOutputSchemaDefinition {

    enum Fields {
        static let findings            = "findings"
        static let symptomId           = "symptom_id"
        static let confidence          = "confidence"
        static let plainDescription    = "plain_description"
        static let imageQuality        = "image_quality"
        static let hasConcerningPattern = "has_concerning_pattern"
        static let uncertain           = "uncertain"
    }

    static func formatInstructions() -> String {
        """
        OUTPUT FORMAT — respond with valid JSON only, no markdown, no other text:
        {
          "findings": [
            {
              "symptom_id": "<exact id from the reference list>",
              "confidence": "<high|medium|low>",
              "plain_description": "<one sentence describing what is visually visible>"
            }
          ],
          "image_quality": "<good|fair|poor>",
          "has_concerning_pattern": <true|false>,
          "uncertain": <true|false>
        }

        Definitions:
        - findings: empty array if nothing is clearly visible or the image is too poor to assess.
        - confidence high: clearly and unambiguously visible. medium: likely present, \
        some uncertainty. low: possibly present, significant uncertainty.
        - image_quality good: clear, well-lit, well-framed. fair: somewhat unclear but \
        analyzable. poor: too blurry, too dark, or too small to analyze reliably.
        - has_concerning_pattern: true only if the visual pattern is associated with a \
        serious condition warranting urgent attention beyond what the individual identifiers convey.
        - uncertain: true if quality or ambiguity prevents reliable extraction.
        """
    }
}
