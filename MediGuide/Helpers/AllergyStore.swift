import Foundation

enum AllergyStore {

    // MARK: - Load

    static func load(profileId: UUID) -> [AllergyEntry] {
        let entries = KeychainManager.load([AllergyEntry].self,
                                           for: StorageKeys.Keychain.allergies(for: profileId)) ?? []
        return sorted(entries)
    }

    // MARK: - Save (full list)

    @discardableResult
    static func save(_ allergies: [AllergyEntry], profileId: UUID) -> Bool {
        KeychainManager.save(sorted(allergies), for: StorageKeys.Keychain.allergies(for: profileId))
    }

    // MARK: - Add single entry

    @discardableResult
    static func add(_ entry: AllergyEntry, profileId: UUID) -> Bool {
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
    static func update(_ entry: AllergyEntry, profileId: UUID) -> Bool {
        var current = load(profileId: profileId)
        guard let idx = current.firstIndex(where: { $0.id == entry.id }) else { return false }
        current[idx] = entry
        return save(current, profileId: profileId)
    }

    // MARK: - Delete all (on profile deletion)

    static func deleteAll(profileId: UUID) {
        KeychainManager.delete(for: StorageKeys.Keychain.allergies(for: profileId))
    }

    // MARK: - Sorting (anaphylactic first, then descending severity, then alphabetical)

    static func sorted(_ entries: [AllergyEntry]) -> [AllergyEntry] {
        entries.sorted {
            if $0.severity != $1.severity { return $0.severity > $1.severity }
            return $0.allergen.localizedCaseInsensitiveCompare($1.allergen) == .orderedAscending
        }
    }
}
