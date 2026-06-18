import Foundation

enum AllergyCategory: String, Codable, CaseIterable {
    case medication     = "medication"
    case food           = "food"
    case insect         = "insect"
    case environmental  = "environmental"
    case latex          = "latex"
    case contrastDye    = "contrast_dye"
    case other          = "other"

    var displayName: String {
        switch self {
        case .medication:    return "Medication"
        case .food:          return "Food"
        case .insect:        return "Insect Sting"
        case .environmental: return "Environmental"
        case .latex:         return "Latex"
        case .contrastDye:   return "Contrast Dye"
        case .other:         return "Other"
        }
    }

    var icon: String {
        switch self {
        case .medication:    return "pills.fill"
        case .food:          return "fork.knife"
        case .insect:        return "ant.fill"
        case .environmental: return "leaf.fill"
        case .latex:         return "hand.raised.fill"
        case .contrastDye:   return "drop.fill"
        case .other:         return "questionmark.circle.fill"
        }
    }

    // How much this category contributes to standing triage modifiers
    enum TriageRelevance { case high, medium, low, informational }

    var triageRelevance: TriageRelevance {
        switch self {
        case .medication:    return .high
        case .food:          return .high
        case .insect:        return .high
        case .environmental: return .low
        case .latex:         return .informational
        case .contrastDye:   return .informational
        case .other:         return .medium
        }
    }
}

enum AllergySeverity: String, Codable, CaseIterable, Comparable {
    case mild          = "mild"
    case moderate      = "moderate"
    case severe        = "severe"
    case anaphylactic  = "anaphylactic"

    var displayName: String {
        switch self {
        case .mild:         return "Mild"
        case .moderate:     return "Moderate"
        case .severe:       return "Severe"
        case .anaphylactic: return "Anaphylactic"
        }
    }

    // Higher = more dangerous; used for sorting and comparison
    var priority: Int {
        switch self {
        case .mild:         return 1
        case .moderate:     return 2
        case .severe:       return 3
        case .anaphylactic: return 4
        }
    }

    static func < (lhs: AllergySeverity, rhs: AllergySeverity) -> Bool {
        lhs.priority < rhs.priority
    }
}
