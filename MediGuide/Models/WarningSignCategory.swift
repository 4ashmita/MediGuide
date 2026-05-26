import Foundation

struct WarningSignsData: Codable {
    let universalWarnings: [String: [String]]
    let symptomSpecificWarnings: [String: [String]]
}
