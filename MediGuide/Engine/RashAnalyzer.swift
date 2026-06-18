import Foundation

enum RashAnalyzer {
    private static let ownedIds: Set<String> = ["hives_sudden", "rash_with_fever_child"]

    /// Analyzes rash-category findings and calibrates confidence using clinical co-occurrence rules.
    /// - `allFindings`: the full set of Claude's findings for cross-category context.
    static func analyze(
        findings: [VisualExtractionResult.Finding],
        allFindings: [VisualExtractionResult.Finding]
    ) -> [CalibratedFinding] {
        let ownedFindings = findings.filter { ownedIds.contains($0.symptomId) }
        let coOccurringIds = Set(allFindings.map(\.symptomId))

        return ownedFindings.map { finding in
            var conf = finding.confidence
            var note: String? = nil
            var hard = false

            // Hives co-occurring with throat or systemic allergic signs = anaphylaxis pattern.
            // Escalate to high regardless of original confidence.
            if finding.symptomId == "hives_sudden",
               coOccurringIds.contains("throat_tightening") || coOccurringIds.contains("severe_allergic_reaction") {
                conf = .high
                note = "Hives co-occurring with throat/allergic signs — anaphylaxis pattern"
                hard = true
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
