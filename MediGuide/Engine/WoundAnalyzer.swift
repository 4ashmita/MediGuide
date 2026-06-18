import Foundation

enum WoundAnalyzer {
    private static let ownedIds: Set<String> = ["fall_with_injury", "severe_bleeding"]

    // Red streaking in a wound description is a hard infection/sepsis indicator.
    // These terms are checked against Claude's plain_description for the finding.
    private static let infectionTerms = ["streak", "red line", "spreading redness", "lymph"]

    /// Analyzes wound-category findings. Applies the red-streaking escalation rule and
    /// flags compound severity when injury and active bleeding co-occur.
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

            // Active bleeding at medium or high confidence is always clinically significant.
            if finding.symptomId == "severe_bleeding", conf != .low {
                hard = true
            }

            // Red streaking → infection/sepsis risk; override any lower confidence.
            let descLowercased = finding.plainDescription.lowercased()
            if infectionTerms.contains(where: { descLowercased.contains($0) }) {
                conf = .high
                notes.append("Wound description suggests red streaking — possible infection or sepsis indicator")
                hard = true
            }

            // Wound + active bleeding together = compound severity; note for UI.
            if finding.symptomId == "fall_with_injury",
               coOccurringIds.contains("severe_bleeding") {
                notes.append("Wound with concurrent active bleeding — compound severity")
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
