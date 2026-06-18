import Foundation

enum BloodType: String, Codable, CaseIterable {
    case aPositive  = "A+"
    case aNegative  = "A-"
    case bPositive  = "B+"
    case bNegative  = "B-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case oPositive  = "O+"
    case oNegative  = "O-"
    case unknown    = "Unknown"

    var storageCode: String {
        switch self {
        case .aPositive:  return "A_POS"
        case .aNegative:  return "A_NEG"
        case .bPositive:  return "B_POS"
        case .bNegative:  return "B_NEG"
        case .abPositive: return "AB_POS"
        case .abNegative: return "AB_NEG"
        case .oPositive:  return "O_POS"
        case .oNegative:  return "O_NEG"
        case .unknown:    return "UNKNOWN"
        }
    }

    var description: String {
        switch self {
        case .aPositive:  return "Can receive A+ and A-, O+ and O-"
        case .aNegative:  return "Can receive A- and O- only"
        case .bPositive:  return "Can receive B+ and B-, O+ and O-"
        case .bNegative:  return "Can receive B- and O- only"
        case .abPositive: return "Universal recipient — can receive any blood type"
        case .abNegative: return "Can receive A-, B-, AB-, and O-"
        case .oPositive:  return "Can receive O+ and O- only"
        case .oNegative:  return "Universal donor — can donate to anyone"
        case .unknown:    return "Blood type not on file — responders will use O negative"
        }
    }
}
