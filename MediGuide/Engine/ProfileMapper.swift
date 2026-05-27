import Foundation

enum ProfileMapper {

    static func modifiers(from profile: UserProfile) -> [Modifier] {
        profile.conditions.compactMap { conditionId in
            guard let entry = ConditionList.entry(for: conditionId),
                  let weight = modifierWeight(entry.modifierId) else { return nil }
            return Modifier(modifierId: entry.modifierId, weight: weight)
        }
    }

    private static func modifierWeight(_ modifierId: String) -> Int? {
        // Weights are authoritative in ConditionList — use the first matching entry
        ConditionList.all.first { $0.modifierId == modifierId }?.weight
    }
}
