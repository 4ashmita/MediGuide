import Foundation

enum MedicationStore {

    // MARK: - Load

    static func load(profileId: UUID) -> [MedicationEntry] {
        KeychainManager.load([MedicationEntry].self,
                             for: StorageKeys.Keychain.medications(for: profileId)) ?? []
    }

    // MARK: - Save (full list)

    @discardableResult
    static func save(_ medications: [MedicationEntry], profileId: UUID) -> Bool {
        KeychainManager.save(medications, for: StorageKeys.Keychain.medications(for: profileId))
    }

    // MARK: - Add single entry

    @discardableResult
    static func add(_ entry: MedicationEntry, profileId: UUID) -> Bool {
        var current = load(profileId: profileId)
        current.append(entry)
        return save(current, profileId: profileId)
    }

    // MARK: - Delete single entry

    @discardableResult
    static func delete(id: UUID, profileId: UUID) -> Bool {
        var current = load(profileId: profileId)
        current.removeAll { $0.id == id }
        return save(current, profileId: profileId)
    }

    // MARK: - Update single entry

    @discardableResult
    static func update(_ entry: MedicationEntry, profileId: UUID) -> Bool {
        var current = load(profileId: profileId)
        guard let idx = current.firstIndex(where: { $0.id == entry.id }) else { return false }
        current[idx] = entry
        return save(current, profileId: profileId)
    }

    // MARK: - Delete all (on profile deletion)

    static func deleteAll(profileId: UUID) {
        KeychainManager.delete(for: StorageKeys.Keychain.medications(for: profileId))
    }
}
