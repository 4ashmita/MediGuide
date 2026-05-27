import Foundation

enum BiologicalSex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case preferNotToSay = "Prefer not to say"
}

enum BloodType: String, Codable, CaseIterable {
    case aPositive = "A+"
    case aNegative = "A-"
    case bPositive = "B+"
    case bNegative = "B-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case oPositive = "O+"
    case oNegative = "O-"
    case unknown = "Unknown"
}


struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var displayName: String
    var dateOfBirth: Date
    var biologicalSex: BiologicalSex
    var bloodType: BloodType = .unknown
    var conditions: [String] = []
    var conditionOtherNote: String = ""
    var medications: [String] = []
    var allergies: [String] = []
    var emergencyContactName: String = ""
    var emergencyContactPhone: String = ""
    var dateCreated: Date = Date()
    var dateModified: Date = Date()

    var ageGroup: AgeGroup {
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
        switch age {
        case ..<2:  return .infant
        case 2..<13: return .child
        case 13..<65: return .adult
        default:    return .elderly
        }
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
}
