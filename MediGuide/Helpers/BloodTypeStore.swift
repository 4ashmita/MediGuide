import Foundation

enum BloodTypeStore {

    // MARK: - Load

    static func load(profileId: UUID) -> BloodType {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.Defaults.bloodType(for: profileId)),
              let decoded = EncryptionManager.decrypt(BloodType.self, from: data) else {
            return .unknown
        }
        return decoded
    }

    // MARK: - Save

    @discardableResult
    static func save(_ type: BloodType, profileId: UUID) -> Bool {
        guard let encrypted = EncryptionManager.encrypt(type) else { return false }
        UserDefaults.standard.set(encrypted, forKey: StorageKeys.Defaults.bloodType(for: profileId))
        return true
    }

    // MARK: - Delete (on profile deletion)

    static func delete(profileId: UUID) {
        UserDefaults.standard.removeObject(forKey: StorageKeys.Defaults.bloodType(for: profileId))
    }
}
