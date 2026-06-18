import Foundation

enum BurnAnalyzer {

    // No dedicated burn symptom IDs exist in the current decision tree.
    // This analyzer inspects the plain_description of any finding for burn-pattern language
    // and applies the facial/airway escalation rule — burns to those regions
    // require immediate escalation regardless of which symptom ID Claude mapped.
    private static let burnTerms   = ["burn", "blister", "char", "scald", "singed"]
    private static let facialTerms = ["face", "facial", "airway", "lip", "mouth", "nose"]

    /// Scans ALL findings for burn-pattern descriptions and produces escalated
    /// CalibratedFindings for any that match. The aggregator deduplicates if another
    /// analyzer already produced a finding for the same symptomId.
    static func analyze(findings: [VisualExtractionResult.Finding]) -> [CalibratedFinding] {
        findings.compactMap { finding in
            let desc = finding.plainDescription.lowercased()
            guard burnTerms.contains(where: { desc.contains($0) }) else { return nil }

            let isFacial = facialTerms.contains(where: { desc.contains($0) })
            let note = isFacial
                ? "Burn description involves facial or airway region — airway compromise risk"
                : "Burn pattern detected in image description"

            return CalibratedFinding(
                symptomId: finding.symptomId,
                originalFinding: finding,
                calibratedConfidence: isFacial ? .high : finding.confidence,
                clinicalNote: note,
                isHardEscalation: isFacial
            )
        }
    }
}
