import Foundation

enum EyeSymptomAnalyzer {
    private static let ownedIds: Set<String> = [
        "stroke_symptoms", "new_weakness_one_side", "soft_spot_bulging"
    ]

    // Pupil asymmetry is a hard neurological flag detectable visually.
    // These terms are matched against Claude's plain_description.
    private static let pupilTerms = ["pupil", "unequal", "asymmetric", "dilated", "fixed"]

    /// Calibrates neurological visual findings. Pupil asymmetry in any description is a hard
    /// flag regardless of which symptom ID Claude assigned. Stroke + unilateral weakness
    /// co-occurring is treated as a compound stroke signal. A bulging fontanelle at non-low
    /// confidence is escalated for intracranial pressure concern.
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

            // Pupil asymmetry anywhere in the description = hard neurological flag.
            let desc = finding.plainDescription.lowercased()
            if pupilTerms.contains(where: { desc.contains($0) }) {
                conf = .high
                notes.append("Pupil asymmetry detected — hard neurological flag")
                hard = true
            }

            // Stroke finding + unilateral weakness together = compound stroke signal.
            if finding.symptomId == "stroke_symptoms",
               coOccurringIds.contains("new_weakness_one_side") {
                conf = .high
                notes.append("Stroke findings with unilateral weakness — compound neurological signal")
                hard = true
            }

            // Bulging fontanelle at non-low confidence = intracranial pressure concern.
            if finding.symptomId == "soft_spot_bulging", conf != .low {
                conf = .high
                notes.append("Bulging fontanelle — intracranial pressure concern")
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
