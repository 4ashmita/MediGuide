import Foundation

struct MedicationEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var dateAdded: Date = Date()
    var note: String = ""
}
