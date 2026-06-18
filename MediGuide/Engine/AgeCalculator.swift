import Foundation

enum AgeCalculator {

    static func ageGroup(from dateOfBirth: Date) -> AgeGroup {
        let years = age(from: dateOfBirth)
        switch years {
        case ..<2:    return .infant
        case 2..<13:  return .child
        case 13..<18: return .teenager
        case 18..<65: return .adult
        default:      return .elderly
        }
    }

    static func age(from dateOfBirth: Date) -> Int {
        let today = Date()
        // Future DOB or implausible age → safe default
        guard dateOfBirth < today else { return 30 }
        let years = Calendar.current.dateComponents([.year], from: dateOfBirth, to: today).year ?? 0
        guard years <= 130 else { return 30 }
        return years
    }
}
