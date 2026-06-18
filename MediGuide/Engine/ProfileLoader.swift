import Foundation

enum ProfileLoaderError: Error {
    case profileNotFound
}

enum ProfileLoader {

    /// Loads the profile for `profileId`, applies all modifiers and emergency data to the engine,
    /// and throws if the profile cannot be retrieved.
    @discardableResult
    static func load(profileId: UUID, into engine: TriageEngine) throws -> ProfileMappingResult {
        guard let profile = ProfileStore.load(id: profileId) else {
            throw ProfileLoaderError.profileNotFound
        }

        let result = ProfileMapper.map(profile)
        apply(result, to: engine)
        return result
    }

    // MARK: - Engine Application

    private static func apply(_ result: ProfileMappingResult, to engine: TriageEngine) {
        engine.setAgeGroup(result.ageGroup)

        for modifier in result.modifiers {
            engine.addModifier(modifier.modifierId)
        }

        engine.setEmergencyContact(
            name: result.emergencyContactName,
            phone: result.emergencyContactPhone
        )
        engine.setSessionMedicationList(result.formattedMedications)
        engine.setRecentMedicationDetected(result.recentMedicationDetected)
        engine.setSessionAllergyList(result.formattedAllergies)
        engine.setAllergyAnaphylacticPresent(result.allergyAnaphylacticPresent)
        engine.setSessionBloodType(result.formattedBloodType)
        engine.setSessionDisplayName(result.displayName)
        engine.setSessionAge(result.age)
        engine.setConditionsExplicitlyProvided(true)
        engine.setProfileUsed(true)
    }
}
