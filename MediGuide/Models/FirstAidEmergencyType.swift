import Foundation

enum FirstAidEmergencyType: String, CaseIterable {
    case cprAdult       = "cpr_adult"
    case cprInfant      = "cpr_infant"
    case severebleeding = "severe_bleeding"
    case anaphylaxis    = "anaphylaxis"
    case cardiac        = "cardiac"
    case stroke         = "stroke"
    case seizure        = "seizure"
    case general        = "general"

    var displayName: String {
        switch self {
        case .cprAdult:       return "CPR — Adult"
        case .cprInfant:      return "CPR — Infant / Child"
        case .severebleeding: return "Severe Bleeding"
        case .anaphylaxis:    return "Anaphylaxis"
        case .cardiac:        return "Cardiac Emergency"
        case .stroke:         return "Stroke Response"
        case .seizure:        return "Seizure Response"
        case .general:        return "Emergency First Aid"
        }
    }

    var tier: RecommendationTier {
        switch self {
        case .cprAdult, .cprInfant, .severebleeding, .anaphylaxis:
            return .call911
        case .cardiac, .stroke, .seizure:
            return .goToER
        case .general:
            return .urgentCare
        }
    }

    // Maps the active triage session to the highest-priority emergency type.
    static func resolve(from session: TriageSession) -> FirstAidEmergencyType {
        let symptoms = Set(session.symptoms.map { $0.symptomId })
        let isSmall  = session.ageGroup == .infant || session.ageGroup == .child

        // Hard-override symptoms in priority order
        if symptoms.contains("unconscious") || symptoms.contains("blue_lips") {
            return isSmall ? .cprInfant : .cprAdult
        }
        if symptoms.contains("difficulty_breathing") {
            return isSmall ? .cprInfant : .cprAdult
        }
        if symptoms.contains("chest_pain") { return .cardiac }
        if symptoms.contains("severe_allergic_reaction") { return .anaphylaxis }
        if symptoms.contains("stroke_symptoms") || symptoms.contains("new_weakness_one_side") {
            return .stroke
        }
        if symptoms.contains("seizure") { return .seizure }
        if symptoms.contains("severe_bleeding") { return .severebleeding }

        // Secondary symptoms
        if symptoms.contains("throat_tightening") { return .anaphylaxis }
        if symptoms.contains("sudden_confusion_elderly") { return .stroke }
        if symptoms.contains("high_fever_infant") || symptoms.contains("lethargy_infant")
            || symptoms.contains("soft_spot_bulging") { return .cprInfant }
        if symptoms.contains("rapid_heartrate") { return .cardiac }
        if symptoms.contains("fall_unable_to_get_up") || symptoms.contains("fall_with_injury") {
            return .severebleeding
        }

        return .general
    }
}
