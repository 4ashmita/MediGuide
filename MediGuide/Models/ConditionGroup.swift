import Foundation

enum ConditionCategory: String, CaseIterable {
    case cardiovascular  = "Cardiovascular"
    case metabolic       = "Metabolic"
    case respiratory     = "Respiratory"
    case immune          = "Immune System"
    case reproductive    = "Reproductive"
    case neurological    = "Neurological"
    case organFunction   = "Organ Function"
    case mentalHealth    = "Mental Health"
    case other           = "Other"
}

struct ConditionGroup: Identifiable {
    let id = UUID()
    let category: ConditionCategory
    let conditions: [ConditionEntry]
    var isExpanded: Bool
    var activeCount: Int
}
