import Foundation

enum DeletionVerifier {

    // MARK: - Individual Profile

    /// Returns true if every storage entry for the given profile ID is gone.
    static func verifyProfileDeletion(id: UUID) -> Bool {
        let ud = UserDefaults.standard
        let udKeys: [String] = [
            StorageKeys.Defaults.displayName(for: id),
            StorageKeys.Defaults.dateOfBirth(for: id),
            StorageKeys.Defaults.biologicalSex(for: id),
            StorageKeys.Defaults.bloodType(for: id),
            StorageKeys.Defaults.dateCreated(for: id),
            StorageKeys.Defaults.dateModified(for: id),
            StorageKeys.Defaults.lastUsed(for: id),
            StorageKeys.Defaults.conditionsSummary(for: id),
            StorageKeys.Defaults.relationship(for: id)
        ]
        for key in udKeys where ud.object(forKey: key) != nil { return false }

        let keychainKeys: [String] = [
            StorageKeys.Keychain.sensitiveData(for: id),
            StorageKeys.Keychain.medications(for: id),
            StorageKeys.Keychain.allergies(for: id)
        ]
        for key in keychainKeys where KeychainManager.exists(for: key) { return false }

        return true
    }

    // MARK: - Full Wipe

    /// Returns true if the master list is empty and every former profile is fully deleted.
    static func verifyFullWipe(formerIds: [UUID]) -> Bool {
        guard ProfileRepository.profileCount == 0 else { return false }
        return formerIds.allSatisfy { verifyProfileDeletion(id: $0) }
    }
}
