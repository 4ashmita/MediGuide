import Foundation

struct AllergyEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var allergen: String
    var category: AllergyCategory
    var severity: AllergySeverity
    var reactionDescription: String = ""
    var carriesEpiPen: Bool = false
    var dateAdded: Date = Date()
}
