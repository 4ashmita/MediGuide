import Foundation

enum FirstAidLibrary {

    private static let allSets: [String: FirstAidInstructionSet] = {
        guard let url = Bundle.main.url(forResource: "FirstAidContent", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: FirstAidInstructionSet].self, from: data)
        else { fatalError("FirstAidContent.json missing or malformed") }
        return decoded
    }()

    static func instructionSet(for type: FirstAidEmergencyType) -> FirstAidInstructionSet? {
        allSets[type.rawValue]
    }

    static func allTypes() -> [FirstAidEmergencyType] {
        FirstAidEmergencyType.allCases.filter { allSets[$0.rawValue] != nil }
    }
}
