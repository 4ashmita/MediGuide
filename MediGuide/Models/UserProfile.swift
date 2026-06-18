import Foundation

enum ProfileRelationship: String, Codable, CaseIterable {
    case parent   = "Parent"
    case spouse   = "Spouse / Partner"
    case child    = "Child"
    case sibling  = "Sibling"
    case other    = "Other"

    var icon: String {
        switch self {
        case .parent:  return "figure.2.arms.open"
        case .spouse:  return "heart.fill"
        case .child:   return "figure.child"
        case .sibling: return "person.2.fill"
        case .other:   return "person.fill"
        }
    }
}

enum BiologicalSex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case preferNotToSay = "Prefer not to say"
}


struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var displayName: String
    var dateOfBirth: Date
    var biologicalSex: BiologicalSex
    var bloodType: BloodType = .unknown
    var conditions: [String] = []
    var relationship: ProfileRelationship? = nil
    var conditionOtherNote: String = ""
    var medications: [MedicationEntry] = []
    var allergies: [AllergyEntry] = []
    var emergencyContactName: String = ""
    var emergencyContactPhone: String = ""
    var dateCreated: Date = Date()
    var dateModified: Date = Date()
    var lastUsed: Date = Date()

    var ageGroup: AgeGroup { AgeCalculator.ageGroup(from: dateOfBirth) }
    var age: Int { AgeCalculator.age(from: dateOfBirth) }
}
