import Foundation

struct ProfileMappingResult {
    let ageGroup: AgeGroup
    let age: Int
    let modifiers: [Modifier]
    let emergencyContactName: String
    let emergencyContactPhone: String
    let formattedMedications: String
    let formattedAllergies: String
    let formattedBloodType: String
    let displayName: String
    let allergyAnaphylacticPresent: Bool
    let recentMedicationDetected: Bool
}

enum ProfileMapper {

    static func map(_ profile: UserProfile) -> ProfileMappingResult {
        let ageGroup = AgeCalculator.ageGroup(from: profile.dateOfBirth)
        var modifiers = conditionModifiers(from: profile)

        // Advanced maternal age auto-detection
        let hasPregnancy = profile.conditions.contains {
            Self.pregnancyConditionIds.contains($0)
        }
        let alreadyFlagged = profile.conditions.contains("advanced_maternal_age")
        if hasPregnancy && AgeCalculator.age(from: profile.dateOfBirth) >= 35 && !alreadyFlagged {
            if let weight = modifierWeight("advanced_maternal_age") {
                modifiers.append(Modifier(modifierId: "advanced_maternal_age", weight: weight))
            }
        }

        // Recent medication change
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentMedication = profile.medications.contains { $0.dateAdded >= thirtyDaysAgo }
        if recentMedication, let weight = modifierWeight("recent_medication_change") {
            modifiers.append(Modifier(modifierId: "recent_medication_change", weight: weight))
        }

        // Allergy standing modifiers
        let hasAnaphylactic = profile.allergies.contains { $0.severity == .anaphylactic }
        let hasSevere = profile.allergies.contains { $0.severity == .severe }
        let hasInsect = profile.allergies.contains { $0.category == .insect }

        if hasAnaphylactic, let weight = modifierWeight("anaphylactic_allergy") {
            modifiers.append(Modifier(modifierId: "anaphylactic_allergy", weight: weight))
        }
        if hasSevere, let weight = modifierWeight("severe_allergy") {
            modifiers.append(Modifier(modifierId: "severe_allergy", weight: weight))
        }
        if hasInsect, let weight = modifierWeight("insect_allergy") {
            modifiers.append(Modifier(modifierId: "insect_allergy", weight: weight))
        }

        return ProfileMappingResult(
            ageGroup: ageGroup,
            age: AgeCalculator.age(from: profile.dateOfBirth),
            modifiers: modifiers,
            emergencyContactName: profile.emergencyContactName,
            emergencyContactPhone: profile.emergencyContactPhone,
            formattedMedications: EmergencyDataFormatter.smsMedicationLine(profile.medications),
            formattedAllergies: EmergencyDataFormatter.smsAllergyLine(profile.allergies),
            formattedBloodType: EmergencyDataFormatter.smsBloodTypeLine(profile.bloodType),
            displayName: profile.displayName,
            allergyAnaphylacticPresent: hasAnaphylactic,
            recentMedicationDetected: recentMedication
        )
    }

    // MARK: - Condition modifiers

    private static func conditionModifiers(from profile: UserProfile) -> [Modifier] {
        profile.conditions.compactMap { conditionId in
            guard let entry = ConditionList.entry(for: conditionId),
                  let weight = modifierWeight(entry.modifierId) else { return nil }
            return Modifier(modifierId: entry.modifierId, weight: weight)
        }
    }

    private static func modifierWeight(_ modifierId: String) -> Int? {
        ConditionList.all.first { $0.modifierId == modifierId }?.weight
    }

    private static let pregnancyConditionIds: Set<String> = [
        "pregnant_t1", "pregnant_t2", "pregnant_t3", "postpartum", "pregnant_unknown"
    ]
}
