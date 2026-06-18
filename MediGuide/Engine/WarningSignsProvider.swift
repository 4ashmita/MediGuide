import Foundation

enum WarningSignsProvider {

    private static let data: WarningSignsData = {
        guard let url = Bundle.main.url(forResource: "WarningSignsData", withExtension: "json"),
              let raw = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(WarningSignsData.self, from: raw)
        else { fatalError("WarningSignsData.json missing or malformed") }
        return decoded
    }()

    static func getWarningSigns(tier: RecommendationTier, symptoms: [Symptom]) -> [String] {
        var signs: [String] = data.universalWarnings[tier.rawValue] ?? []

        for symptom in symptoms {
            if let specific = data.symptomSpecificWarnings[symptom.symptomId] {
                signs.append(contentsOf: specific)
            }
        }

        return deduplicated(signs)
    }

    private static func deduplicated(_ signs: [String]) -> [String] {
        var seen = Set<String>()
        return signs.filter { seen.insert($0).inserted }
    }
}
