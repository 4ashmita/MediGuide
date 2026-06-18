import XCTest
@testable import MediGuide

// MARK: - Shared test fixture

/// Minimal in-memory DecisionTreeData covering the visual symptom IDs that are
/// also hard overrides. Tests use this instead of loading the JSON bundle so they
/// stay fast and independent of the resource file.
private func makeTestTreeData(
    extraSymptomWeights: [String: Int] = [:],
    extraHardOverrides: [String] = []
) -> DecisionTreeData {
    let baseWeights: [String: Int] = [
        // Visual hard-override IDs
        "blue_lips":             20,
        "stroke_symptoms":       20,
        "severe_bleeding":       20,
        "severe_allergic_reaction": 20,
        "soft_spot_bulging":     20,
        "new_weakness_one_side": 20,
        // Non-override visual IDs
        "hives_sudden":          8,
        "swelling_sudden":       8,
        "rash_with_fever_child": 8,
        "fall_with_injury":      8,
        "throat_tightening":     10,
    ]
    let weights = baseWeights.merging(extraSymptomWeights) { _, new in new }

    let baseOverrides = [
        "blue_lips", "stroke_symptoms", "severe_bleeding",
        "severe_allergic_reaction", "soft_spot_bulging", "new_weakness_one_side",
    ]
    let overrides = Array(Set(baseOverrides + extraHardOverrides))

    let tiers: [String: DecisionTreeData.TierConfig] = [
        "CALL_911":    .init(minScore: 25),
        "GO_TO_ER":    .init(minScore: 15),
        "URGENT_CARE": .init(minScore: 6),
        "MONITOR":     .init(minScore: 0),
    ]

    return DecisionTreeData(
        version: "test",
        startNode: "start",
        nodes: [:],
        symptomWeights: weights,
        modifierWeights: [:],
        hardOverrides: overrides,
        recommendationTiers: tiers,
        warningSigns: [:]
    )
}

// MARK: - Engine layer: does addSymptom trigger .call911?

final class TriageEngineHardOverrideTests: XCTestCase {

    private var treeData: DecisionTreeData!
    private var engine: TriageEngine!

    override func setUp() {
        super.setUp()
        treeData = makeTestTreeData()
        engine = TriageEngine(treeData: treeData)
    }

    func test_blueLips_immediatelyCall911() {
        engine.addSymptom("blue_lips")
        XCTAssertEqual(engine.currentTier, .call911)
        XCTAssertTrue(engine.session.hardOverrideTriggered)
    }

    func test_strokeSymptoms_immediatelyCall911() {
        engine.addSymptom("stroke_symptoms")
        XCTAssertEqual(engine.currentTier, .call911)
        XCTAssertTrue(engine.session.hardOverrideTriggered)
    }

    func test_severeBleeding_immediatelyCall911() {
        engine.addSymptom("severe_bleeding")
        XCTAssertEqual(engine.currentTier, .call911)
    }

    func test_newWeaknessOneSide_immediatelyCall911() {
        engine.addSymptom("new_weakness_one_side")
        XCTAssertEqual(engine.currentTier, .call911)
    }

    /// Confirms the override fires even when low-weight non-override symptoms are added first,
    /// keeping the score well below the CALL_911 threshold before the override ID arrives.
    func test_overrideFires_regardlessOfLowScore() {
        // hives_sudden weight = 8, CALL_911 threshold = 25 → would only be MONITOR/URGENT_CARE
        engine.addSymptom("hives_sudden")
        XCTAssertNotEqual(engine.currentTier, .call911)

        // Now add a hard override visual symptom — must jump to 911 immediately
        engine.addSymptom("blue_lips")
        XCTAssertEqual(engine.currentTier, .call911)
    }

    func test_nonOverrideVisualSymptom_doesNotCall911() {
        engine.addSymptom("hives_sudden")
        XCTAssertNotEqual(engine.currentTier, .call911)
    }
}

// MARK: - Parsing layer: does the JSON pipeline extract visual hard-override IDs?

final class JSONResponseHandlerVisualTests: XCTestCase {

    private var treeData: DecisionTreeData!

    override func setUp() {
        super.setUp()
        treeData = makeTestTreeData()
    }

    // MARK: Happy path

    func test_blueLips_highConfidence_extractedCorrectly() throws {
        let json = """
        {
          "findings": [
            {
              "symptom_id": "blue_lips",
              "confidence": "high",
              "plain_description": "Visible blue discoloration of the lips."
            }
          ],
          "image_quality": "good",
          "has_concerning_pattern": true,
          "uncertain": false
        }
        """
        let result = JSONResponseHandler.handleVisual(json, treeData: treeData)
        let findings = try XCTUnwrap(result.value)
        XCTAssertTrue(findings.symptoms.contains { $0.symptomId == "blue_lips" },
                      "blue_lips must appear in engine-ready symptoms")
    }

    func test_strokeSymptoms_extractedAndEngineTriggersCall911() throws {
        let json = """
        {
          "findings": [
            {
              "symptom_id": "stroke_symptoms",
              "confidence": "high",
              "plain_description": "Visible facial drooping on the left side."
            }
          ],
          "image_quality": "good",
          "has_concerning_pattern": true,
          "uncertain": false
        }
        """
        let findings = try XCTUnwrap(JSONResponseHandler.handleVisual(json, treeData: treeData).value)
        let engine = TriageEngine(treeData: treeData)

        for symptom in findings.symptoms {
            engine.addSymptom(symptom.symptomId)
        }

        XCTAssertEqual(engine.currentTier, .call911,
                       "Feeding parsed visual findings into the engine must trigger the hard override")
    }

    func test_multipleFindings_hardOverrideAmongThem_enginesCall911() throws {
        // Mix: one non-override visual symptom + one override.
        // Score from hives_sudden alone is below 911 threshold.
        let json = """
        {
          "findings": [
            {
              "symptom_id": "hives_sudden",
              "confidence": "medium",
              "plain_description": "Raised welts visible on forearm."
            },
            {
              "symptom_id": "blue_lips",
              "confidence": "high",
              "plain_description": "Blue tinge around the lips."
            }
          ],
          "image_quality": "good",
          "has_concerning_pattern": true,
          "uncertain": false
        }
        """
        let findings = try XCTUnwrap(JSONResponseHandler.handleVisual(json, treeData: treeData).value)
        let engine = TriageEngine(treeData: treeData)
        findings.symptoms.forEach { engine.addSymptom($0.symptomId) }

        XCTAssertEqual(engine.currentTier, .call911)
    }

    // MARK: Poor image quality caps confidence

    func test_poorQuality_highConfidenceCappedToMedium() throws {
        let json = """
        {
          "findings": [
            {
              "symptom_id": "hives_sudden",
              "confidence": "high",
              "plain_description": "Possible rash, image is blurry."
            }
          ],
          "image_quality": "poor",
          "has_concerning_pattern": false,
          "uncertain": false
        }
        """
        let findings = try XCTUnwrap(JSONResponseHandler.handleVisual(json, treeData: treeData).value)
        let finding = try XCTUnwrap(findings.fullResult.findings.first)
        XCTAssertEqual(finding.confidence, .medium,
                       "Poor image quality must cap high confidence down to medium")
    }

    /// Hard-override symptoms must still produce .call911 even when the image is poor.
    func test_poorQuality_doesNotPreventHardOverride() throws {
        let json = """
        {
          "findings": [
            {
              "symptom_id": "blue_lips",
              "confidence": "high",
              "plain_description": "Lips appear bluish despite blurry image."
            }
          ],
          "image_quality": "poor",
          "has_concerning_pattern": true,
          "uncertain": false
        }
        """
        let findings = try XCTUnwrap(JSONResponseHandler.handleVisual(json, treeData: treeData).value)
        // Confidence is capped to medium, but the symptom still passes through to the engine.
        let engine = TriageEngine(treeData: treeData)
        findings.symptoms.forEach { engine.addSymptom($0.symptomId) }
        XCTAssertEqual(engine.currentTier, .call911,
                       "Hard override must fire regardless of image quality confidence cap")
    }

    // MARK: Schema validation

    func test_missingFindingsField_rejected() {
        let json = """
        { "image_quality": "good", "has_concerning_pattern": false, "uncertain": false }
        """
        let result = JSONResponseHandler.handleVisual(json, treeData: treeData)
        guard case .failure(let error) = result else {
            XCTFail("Expected failure for missing 'findings' field"); return
        }
        if case .validationFailed(let reason) = error {
            XCTAssertTrue(reason.contains("findings"), "Error reason must name the violated field")
        } else {
            XCTFail("Expected .validationFailed, got \(error)")
        }
    }

    func test_unknownSymptomID_rejected() {
        let json = """
        {
          "findings": [
            {
              "symptom_id": "invented_symptom_xyz",
              "confidence": "high",
              "plain_description": "This ID does not exist in the decision tree."
            }
          ],
          "image_quality": "good",
          "has_concerning_pattern": false,
          "uncertain": false
        }
        """
        let result = JSONResponseHandler.handleVisual(json, treeData: treeData)
        XCTAssertNil(result.value, "Unknown symptom ID must be rejected — never silently passed to the engine")
    }

    func test_invalidConfidenceValue_treatedAsLow() throws {
        // "definitely" is not a valid confidence string — mapper falls back to .low.
        // Low-confidence findings don't appear in engine-ready symptoms but do appear in fullResult.
        let json = """
        {
          "findings": [
            {
              "symptom_id": "hives_sudden",
              "confidence": "definitely",
              "plain_description": "Rash visible."
            }
          ],
          "image_quality": "good",
          "has_concerning_pattern": false,
          "uncertain": false
        }
        """
        // Schema validation allows unknown confidence strings through (ConfidenceLevelMapper
        // handles normalization, not SchemaEnforcer). The finding arrives as .low confidence.
        let findings = try XCTUnwrap(JSONResponseHandler.handleVisual(json, treeData: treeData).value)
        // Engine-ready symptoms exclude low confidence.
        XCTAssertTrue(findings.symptoms.isEmpty,
                      "Unrecognized confidence falls back to .low — excluded from engine-ready symptoms")
        // But the finding is present in fullResult for the confirmation UI.
        XCTAssertFalse(findings.fullResult.findings.isEmpty)
        XCTAssertEqual(findings.fullResult.findings.first?.confidence, .low)
    }

    // MARK: ResponseSanitizer

    func test_piiInPlainDescription_redacted() throws {
        let json = """
        {
          "findings": [
            {
              "symptom_id": "hives_sudden",
              "confidence": "high",
              "plain_description": "Patient called 555-123-4567 about this rash."
            }
          ],
          "image_quality": "good",
          "has_concerning_pattern": false,
          "uncertain": false
        }
        """
        let findings = try XCTUnwrap(JSONResponseHandler.handleVisual(json, treeData: treeData).value)
        let desc = try XCTUnwrap(findings.fullResult.findings.first?.plainDescription)
        XCTAssertFalse(desc.contains("555-123-4567"), "Phone number must be redacted from plain_description")
        XCTAssertTrue(desc.contains("[number]"))
    }
}

// MARK: - Text response handler

final class JSONResponseHandlerTextTests: XCTestCase {

    private var treeData: DecisionTreeData!

    override func setUp() {
        super.setUp()
        treeData = makeTestTreeData()
    }

    func test_unknownSymptomID_rejected() {
        let json = """
        {
          "symptoms": ["invented_id"],
          "modifiers": [],
          "hard_override_detected": false,
          "uncertain": false,
          "summary": "Test."
        }
        """
        XCTAssertNil(JSONResponseHandler.handleText(json, treeData: treeData).value)
    }

    func test_missingRequiredField_rejected() {
        // Missing 'uncertain' field — schema violation
        let json = """
        { "symptoms": [], "modifiers": [], "hard_override_detected": false, "summary": "" }
        """
        let result = JSONResponseHandler.handleText(json, treeData: treeData)
        guard case .failure(let error) = result else {
            XCTFail("Expected failure for missing 'uncertain' field"); return
        }
        if case .validationFailed(let reason) = error {
            XCTAssertTrue(reason.contains("uncertain"))
        } else {
            XCTFail("Expected .validationFailed, got \(error)")
        }
    }

    func test_piiInSummary_redacted() throws {
        let json = """
        {
          "symptoms": [],
          "modifiers": [],
          "hard_override_detected": false,
          "uncertain": false,
          "summary": "User reported symptoms, email user@example.com."
        }
        """
        let parsed = try XCTUnwrap(JSONResponseHandler.handleText(json, treeData: treeData).value)
        XCTAssertFalse(parsed.summary.contains("user@example.com"))
        XCTAssertTrue(parsed.summary.contains("[email]"))
    }
}

// MARK: - Result convenience

private extension Result {
    var value: Success? {
        guard case .success(let v) = self else { return nil }
        return v
    }
}
