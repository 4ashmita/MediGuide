import Foundation

enum VisualSymptomParser {

    struct ParsedVisualFindings {
        let symptoms: [Symptom]                      // high + medium confidence; for TriageEngine
        let fullResult: VisualExtractionResult       // complete raw result including low-confidence; for UI
        let calibratedFindings: [CalibratedFinding]  // analyzer-calibrated findings; for UI detail
    }

    /// Full pipeline: decode JSON → validate IDs → route through domain analyzers →
    /// aggregate and deduplicate → return ready-to-score Symptom list.
    static func parse(_ jsonText: String, treeData: DecisionTreeData) -> Result<ParsedVisualFindings, APIError> {
        guard let result = decodeJSON(jsonText) else {
            return .failure(.invalidResponse)
        }

        let knownSymptoms = Set(treeData.symptomWeights.keys)
        let allIds = result.findings.map(\.symptomId)

        switch SymptomIDValidator.validateVisualIds(allIds, knownSymptoms: knownSymptoms) {
        case .failure(let error): return .failure(error)
        case .success: break
        }

        let calibrated = routeToAnalyzers(allFindings: result.findings)
        let aggregated = VisualSymptomAggregator.aggregate(calibratedFindings: calibrated, treeData: treeData)

        return .success(ParsedVisualFindings(
            symptoms: aggregated.symptoms,
            fullResult: result,
            calibratedFindings: aggregated.calibratedFindings
        ))
    }

    // MARK: - Private

    private static func routeToAnalyzers(
        allFindings: [VisualExtractionResult.Finding]
    ) -> [CalibratedFinding] {
        var results: [CalibratedFinding] = []
        results += RashAnalyzer.analyze(findings: allFindings,    allFindings: allFindings)
        results += WoundAnalyzer.analyze(findings: allFindings,   allFindings: allFindings)
        results += BurnAnalyzer.analyze(findings: allFindings)
        results += SwellingAnalyzer.analyze(findings: allFindings, allFindings: allFindings)
        results += SkinColorAnalyzer.analyze(findings: allFindings)
        results += EyeSymptomAnalyzer.analyze(findings: allFindings, allFindings: allFindings)
        return results
    }

    // MARK: - JSON Decoding

    static func decodeJSON(_ text: String) -> VisualExtractionResult? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let f = VisualOutputSchemaDefinition.Fields.self

        // Parse image_quality first — needed by ConfidenceLevelMapper to cap confidence on poor images.
        let qualityStr = FieldExtractor.optionalString(f.imageQuality, from: json, default: "fair")
        let quality    = VisualExtractionResult.ImageQuality(rawValue: qualityStr) ?? .fair

        let findingsRaw = FieldExtractor.optionalObjectArray(f.findings, from: json)
        let findings: [VisualExtractionResult.Finding] = findingsRaw.compactMap { dict in
            guard let id = dict[f.symptomId] as? String else { return nil }
            let confStr = FieldExtractor.optionalString(f.confidence, from: dict, default: "low")
            let confidence = ConfidenceLevelMapper.map(confStr, imageQuality: quality)
            let desc = ResponseSanitizer.sanitize(
                FieldExtractor.optionalString(f.plainDescription, from: dict)
            )
            return VisualExtractionResult.Finding(
                symptomId: id,
                confidence: confidence,
                plainDescription: desc
            )
        }

        return VisualExtractionResult(
            findings: findings,
            imageQuality: quality,
            hasConcerningPattern: FieldExtractor.optionalBool(f.hasConcerningPattern, from: json),
            uncertain:            FieldExtractor.optionalBool(f.uncertain,            from: json)
        )
    }
}
