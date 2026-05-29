import Foundation
import Combine

private extension Set {
    func intersects(_ other: Set<Element>) -> Bool { !isDisjoint(with: other) }
}

final class TriageEngine: ObservableObject {

    // MARK: - Published State

    @Published private(set) var session = TriageSession()
    @Published private(set) var currentTier: RecommendationTier = .monitor
    @Published private(set) var warningSigns: [String] = []

    // MARK: - Private

    private let treeData: DecisionTreeData

    // MARK: - Init

    init(treeData: DecisionTreeData) {
        self.treeData = treeData
        evaluate()
    }

    // MARK: - Public Interface

    func addSymptom(_ id: String) {
        guard !session.symptoms.contains(where: { $0.symptomId == id }),
              let weight = treeData.symptomWeights[id] else { return }
        session.symptoms.append(Symptom(symptomId: id, weight: weight))
        evaluate()
    }

    func removeSymptom(_ id: String) {
        session.symptoms.removeAll { $0.symptomId == id }
        session.hardOverrideTriggered = session.symptoms.contains {
            treeData.hardOverrides.contains($0.symptomId)
        }
        evaluate()
    }

    func addModifier(_ id: String) {
        guard !session.modifiers.contains(where: { $0.modifierId == id }),
              let weight = treeData.modifierWeights[id] else { return }
        session.modifiers.append(Modifier(modifierId: id, weight: weight))
        evaluate()
    }

    func removeModifier(_ id: String) {
        session.modifiers.removeAll { $0.modifierId == id }
        evaluate()
    }

    func setAgeGroup(_ group: AgeGroup) {
        session.ageGroup = group
        evaluate()
    }

    func setSessionActive(_ active: Bool) { session.isActive = active }
    func setSessionStartTime(_ time: Date) { session.sessionStartTime = time }
    func setProfileUsed(_ used: Bool) { session.profileUsed = used }
    func setEmergencyContact(name: String, phone: String) {
        session.sessionEmergencyContactName = name
        session.sessionEmergencyContactPhone = phone
    }

    func setSessionMedicationList(_ list: String) { session.sessionMedicationList = list }
    func setRecentMedicationDetected(_ detected: Bool) { session.recentMedicationDetected = detected }
    func setSessionAllergyList(_ list: String) { session.sessionAllergyList = list }
    func setAllergyAnaphylacticPresent(_ present: Bool) { session.allergyAnaphylacticPresent = present }

    func triggerInstinctOverride() {
        guard currentTier != .call911 else { return }
        session.instinctOverrideUsed = true
        session.escalationCount += 1
        evaluate()
    }

    // Returns true if timer should restart, false if escalation took over
    @discardableResult
    func reassess(response: ReassessmentResponse, minutesElapsed: Int) -> Bool {
        let timestamp = "+\(minutesElapsed)min: \(response)"
        session.reassessmentHistory.append(timestamp)
        session.reassessmentCount += 1

        switch response {
        case .better:
            return true

        case .worse:
            addModifier("symptoms_worsening")
            escalateOnReassessment()
            return false

        case .sameMonitor:
            if minutesElapsed >= 240 {
                addModifier("symptoms_not_improving")
                escalateOnReassessment()
                return false
            } else if minutesElapsed >= 120 && session.reassessmentCount >= 2 {
                addModifier("symptoms_not_improving")
                escalateOnReassessment()
                return false
            }
            return true

        case .sameOnWay:
            return true

        case .sameNotGone:
            if currentTier == .urgentCare && minutesElapsed >= 60 {
                addModifier("symptoms_not_improving")
                escalateOnReassessment()
                return false
            }
            return true

        case .cantTravel:
            while currentTier != .call911 {
                escalateOnReassessment()
            }
            return false
        }
    }

    private func escalateOnReassessment() {
        guard currentTier != .call911 else { return }
        session.escalatedViaReassessment = true
        session.escalationCount += 1
        evaluate()
    }

    func reset() {
        session = TriageSession()
        evaluate()
    }

    // MARK: - Scoring

    private func checkHardOverrides() -> Bool {
        session.symptoms.contains {
            treeData.hardOverrides.contains($0.symptomId)
        }
    }

    private func evaluate() {
        if checkHardOverrides() {
            session.hardOverrideTriggered = true
            session.totalScore = Int.max
            applyTier(.call911)
            return
        }

        let base = ScoringCalculator.symptomTotal(from: session.symptoms)
                 + ScoringCalculator.modifierTotal(from: session.modifiers)
        session.totalScore = ScoringCalculator.applyAgeMultiplier(to: base, for: session.ageGroup)

        var tier = ScoringCalculator.mapToTier(score: session.totalScore, tiers: treeData.recommendationTiers)

        for _ in 0 ..< session.escalationCount {
            tier = ScoringCalculator.escalateTier(tier)
        }

        // Preeclampsia combination rule — fires after hard overrides, before final tier
        if let preeclampsiaTier = checkPreeclampsia() {
            if preeclampsiaTier.priority > tier.priority {
                tier = preeclampsiaTier
            }
        }

        // Anaphylaxis combination rules — insect sting + allergy, or anaphylactic allergy + reaction symptoms
        if checkAnaphylaxisCombination() {
            tier = .call911
        }

        applyTier(tier)
    }

    // MARK: - Preeclampsia Rule

    private static let preeclampsiaSymptoms: Set<String> = [
        "severe_headache", "vision_changes", "upper_abdominal_pain_right",
        "swelling_sudden", "sudden_shortness_of_breath", "sudden_nausea_late_pregnancy"
    ]

    private static let pregnancyModifiers: Set<String> = [
        "pregnant_t1", "pregnant_t2", "pregnant_t3", "postpartum", "pregnant"
    ]

    private static let preeclampsiaRiskModifiers: Set<String> = [
        "high_blood_pressure", "diabetic", "diabetic_type1", "diabetic_type2",
        "obesity_severe", "autoimmune", "first_pregnancy", "preeclampsia_history",
        "multiple_gestation", "advanced_maternal_age"
    ]

    private func checkPreeclampsia() -> RecommendationTier? {
        let activeModifierIds = Set(session.modifiers.map { $0.modifierId })
        guard activeModifierIds.intersects(Self.pregnancyModifiers) else { return nil }

        let activeSymptomIds = Set(session.symptoms.map { $0.symptomId })
        let preeclampsiaSymptomCount = activeSymptomIds.intersection(Self.preeclampsiaSymptoms).count
        guard preeclampsiaSymptomCount > 0 else { return nil }

        let hasRiskFactor = activeModifierIds.intersects(Self.preeclampsiaRiskModifiers)
        let threshold = hasRiskFactor ? 1 : 2

        return preeclampsiaSymptomCount >= threshold ? .goToER : nil
    }

    // MARK: - Anaphylaxis Combination Rules

    private static let anaphylaxisReactionSymptoms: Set<String> = [
        "throat_tightening", "hives_sudden", "difficulty_breathing",
        "sudden_shortness_of_breath", "swelling_sudden"
    ]

    private func checkAnaphylaxisCombination() -> Bool {
        let activeModifierIds = Set(session.modifiers.map { $0.modifierId })
        let activeSymptomIds = Set(session.symptoms.map { $0.symptomId })

        // Insect sting + insect allergy → always 911
        if activeSymptomIds.contains("insect_sting") && activeModifierIds.contains("insect_allergy") {
            return true
        }

        // Known anaphylactic allergy + any anaphylaxis reaction symptom → 911
        if activeModifierIds.contains("anaphylactic_allergy")
            && activeSymptomIds.intersects(Self.anaphylaxisReactionSymptoms) {
            return true
        }

        return false
    }

    private func applyTier(_ tier: RecommendationTier) {
        currentTier = tier
        warningSigns = WarningSignsProvider.getWarningSigns(tier: tier, symptoms: session.symptoms)
    }
}
