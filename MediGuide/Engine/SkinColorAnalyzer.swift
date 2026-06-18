import Foundation

enum SkinColorAnalyzer {
    private static let ownedIds: Set<String> = ["blue_lips"]

    // Cyanosis descriptor terms — used to confirm a medium-confidence finding
    // when the description explicitly names a color consistent with cyanosis.
    private static let cyanosisTerms = ["blue", "purple", "gray", "grey", "dusky", "mottl"]

    /// Calibrates skin-color findings. Cyanosis (blue_lips) at high confidence is a hard
    /// respiratory/cardiac flag. Medium confidence is escalated to high when the description
    /// explicitly mentions a cyanotic color. Low-confidence findings pass through unmodified.
    static func analyze(findings: [VisualExtractionResult.Finding]) -> [CalibratedFinding] {
        findings.filter { ownedIds.contains($0.symptomId) }.map { finding in
            var conf = finding.confidence
            var note: String? = nil
            var hard = false

            if finding.symptomId == "blue_lips" {
                switch conf {
                case .high:
                    note = "Visible cyanosis — respiratory or cardiac compromise"
                    hard = true
                case .medium:
                    let desc = finding.plainDescription.lowercased()
                    if cyanosisTerms.contains(where: { desc.contains($0) }) {
                        conf = .high
                        note = "Cyanosis confirmed in description — respiratory or cardiac compromise"
                        hard = true
                    }
                case .low:
                    break
                }
            }

            return CalibratedFinding(
                symptomId: finding.symptomId,
                originalFinding: finding,
                calibratedConfidence: conf,
                clinicalNote: note,
                isHardEscalation: hard
            )
        }
    }
}
