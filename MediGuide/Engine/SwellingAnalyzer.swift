import Foundation

enum SwellingAnalyzer {
    private static let ownedIds: Set<String> = [
        "swelling_sudden", "throat_tightening", "severe_allergic_reaction"
    ]

    /// Calibrates swelling-category findings. Throat tightening at any non-low confidence
    /// is escalated to high — airway compromise cannot be downweighted. Swelling co-occurring
    /// with throat or systemic allergic findings is flagged as an anaphylaxis pattern.
    static func analyze(
        findings: [VisualExtractionResult.Finding],
        allFindings: [VisualExtractionResult.Finding]
    ) -> [CalibratedFinding] {
        let ownedFindings = findings.filter { ownedIds.contains($0.symptomId) }
        let coOccurringIds = Set(allFindings.map(\.symptomId))

        return ownedFindings.map { finding in
            var conf = finding.confidence
            var notes: [String] = []
            var hard = false

            // Throat tightening = potential airway compromise; escalate to high.
            if finding.symptomId == "throat_tightening", conf != .low {
                conf = .high
                notes.append("Throat tightening — potential airway compromise")
                hard = true
            }

            // Sudden swelling with concurrent throat or allergic findings = anaphylaxis pattern.
            if finding.symptomId == "swelling_sudden",
               coOccurringIds.contains("throat_tightening") || coOccurringIds.contains("severe_allergic_reaction") {
                notes.append("Swelling co-occurring with throat or allergic signs — anaphylaxis pattern")
                hard = true
            }

            return CalibratedFinding(
                symptomId: finding.symptomId,
                originalFinding: finding,
                calibratedConfidence: conf,
                clinicalNote: notes.isEmpty ? nil : notes.joined(separator: "; "),
                isHardEscalation: hard
            )
        }
    }
}
