import Foundation

enum VisualSymptomAggregator {

    struct AggregatedResult {
        let symptoms: [Symptom]                      // high + medium confidence; for TriageEngine
        let calibratedFindings: [CalibratedFinding]  // full deduplicated set; for UI display
    }

    /// Deduplicates, resolves conflicts, and maps calibrated findings to Symptom objects
    /// ready for the TriageEngine. Hard-escalation findings bypass the low-confidence filter.
    static func aggregate(
        calibratedFindings: [CalibratedFinding],
        treeData: DecisionTreeData
    ) -> AggregatedResult {
        let deduplicated = deduplicate(calibratedFindings)
        let symptoms = mapToSymptoms(deduplicated, treeData: treeData)
        return AggregatedResult(symptoms: symptoms, calibratedFindings: deduplicated)
    }

    // MARK: - Private

    /// When the same symptomId appears from multiple analyzers (e.g., BurnAnalyzer and
    /// WoundAnalyzer both produce a finding for fall_with_injury), keep whichever version
    /// has the highest clinical priority: hard escalation > confidence rank > has clinical note.
    private static func deduplicate(_ findings: [CalibratedFinding]) -> [CalibratedFinding] {
        var best: [String: CalibratedFinding] = [:]
        for finding in findings {
            let id = finding.symptomId
            guard let existing = best[id] else {
                best[id] = finding
                continue
            }
            if priority(finding) > priority(existing) {
                best[id] = finding
            }
        }
        return Array(best.values)
    }

    /// Priority tuple: (isHardEscalation, confidenceRank, hasNote) — compared lexicographically.
    private static func priority(_ f: CalibratedFinding) -> (Int, Int, Int) {
        (f.isHardEscalation ? 1 : 0,
         f.calibratedConfidence.rank,
         f.clinicalNote != nil ? 1 : 0)
    }

    /// Converts calibrated findings to Symptom objects for the TriageEngine.
    /// Low-confidence findings are dropped unless flagged as hard escalations.
    private static func mapToSymptoms(
        _ findings: [CalibratedFinding],
        treeData: DecisionTreeData
    ) -> [Symptom] {
        findings
            .filter { $0.calibratedConfidence != .low || $0.isHardEscalation }
            .compactMap { finding in
                guard let weight = treeData.symptomWeights[finding.symptomId] else { return nil }
                return Symptom(symptomId: finding.symptomId, weight: weight)
            }
    }
}

private extension VisualExtractionResult.Finding.Confidence {
    var rank: Int {
        switch self {
        case .high:   return 2
        case .medium: return 1
        case .low:    return 0
        }
    }
}
