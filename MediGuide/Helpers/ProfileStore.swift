import Foundation

// Lightweight struct for the profile switcher — no sensitive fields loaded
struct ProfileSummary: Identifiable {
    let id: UUID
    let displayName: String
    let ageGroup: AgeGroup
    let dateOfBirth: Date
    let lastUsed: Date
    let dateModified: Date
    let conditionsSummary: String

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
}

// Sensitive fields stored in Keychain (medications and allergies have their own separate keys)
private struct SensitiveProfileData: Codable {
    var conditions: [String]
    var conditionOtherNote: String
    var emergencyContactName: String
    var emergencyContactPhone: String
}

enum ProfileStoreError: Error {
    case encodingFailed
    case saveFailed
}

enum ProfileStore {

    // MARK: - Save

    static func save(_ profile: UserProfile) throws {
        saveNonSensitive(profile)
        try saveSensitive(profile)
        MedicationStore.save(profile.medications, profileId: profile.id)
        AllergyStore.save(profile.allergies, profileId: profile.id)

        var ids = loadProfileIds()
        if !ids.contains(profile.id) { ids.append(profile.id) }
        saveProfileIds(ids)

        OnboardingManager.markProfileCreated()
    }

    // MARK: - Load

    static func load(id: UUID) -> UserProfile? {
        guard let non = loadNonSensitive(id: id),
              let sensitive = loadSensitive(id: id) else { return nil }
        return assemble(id: id, non: non, sensitive: sensitive)
    }

    static func loadAll() -> [UserProfile] {
        loadProfileIds().compactMap { load(id: $0) }
    }

    static func listSummaries() -> [ProfileSummary] {
        loadProfileIds().compactMap { id in
            guard let non = loadNonSensitive(id: id) else { return nil }
            return ProfileSummary(
                id: id,
                displayName: non.displayName,
                ageGroup: ageGroup(from: non.dateOfBirth),
                dateOfBirth: non.dateOfBirth,
                lastUsed: non.lastUsed,
                dateModified: non.dateModified,
                conditionsSummary: non.conditionsSummary
            )
        }
    }

    // MARK: - Update Last Used

    static func updateLastUsed(id: UUID) {
        guard let encrypted = EncryptionManager.encrypt(Date()) else { return }
        UserDefaults.standard.set(encrypted, forKey: StorageKeys.Defaults.lastUsed(for: id))
    }

    // MARK: - Update

    static func update(_ profile: UserProfile) throws {
        var updated = profile
        updated.dateModified = Date()
        try save(updated)
    }

    // MARK: - Delete

    static func delete(id: UUID) {
        removeNonSensitive(id: id)
        KeychainManager.delete(for: StorageKeys.Keychain.sensitiveData(for: id))
        MedicationStore.deleteAll(profileId: id)
        AllergyStore.deleteAll(profileId: id)

        var ids = loadProfileIds()
        ids.removeAll { $0 == id }
        saveProfileIds(ids)

        if ids.isEmpty { OnboardingManager.resetProfileCreated() }
    }

    // MARK: - Profile ID Index

    private static func loadProfileIds() -> [UUID] {
        guard let encrypted = UserDefaults.standard.data(forKey: StorageKeys.Defaults.profileIndex),
              let ids = EncryptionManager.decrypt([UUID].self, from: encrypted) else { return [] }
        return ids
    }

    private static func saveProfileIds(_ ids: [UUID]) {
        guard let encrypted = EncryptionManager.encrypt(ids) else { return }
        UserDefaults.standard.set(encrypted, forKey: StorageKeys.Defaults.profileIndex)
    }

    // MARK: - Non-sensitive (UserDefaults + encryption)

    private typealias NonSensitive = (
        displayName: String,
        dateOfBirth: Date,
        biologicalSex: BiologicalSex,
        bloodType: BloodType,
        dateCreated: Date,
        dateModified: Date,
        lastUsed: Date,
        conditionsSummary: String
    )

    private static func saveNonSensitive(_ profile: UserProfile) {
        let ud = UserDefaults.standard
        func set<T: Encodable>(_ value: T, key: String) {
            if let encrypted = EncryptionManager.encrypt(value) {
                ud.set(encrypted, forKey: key)
            }
        }
        let id = profile.id
        set(profile.displayName,    key: StorageKeys.Defaults.displayName(for: id))
        set(profile.dateOfBirth,    key: StorageKeys.Defaults.dateOfBirth(for: id))
        set(profile.biologicalSex,  key: StorageKeys.Defaults.biologicalSex(for: id))
        set(profile.bloodType,      key: StorageKeys.Defaults.bloodType(for: id))
        set(profile.dateCreated,    key: StorageKeys.Defaults.dateCreated(for: id))
        set(profile.dateModified,   key: StorageKeys.Defaults.dateModified(for: id))
        set(profile.lastUsed,       key: StorageKeys.Defaults.lastUsed(for: id))

        let summaryNames = profile.conditions.prefix(3).compactMap {
            ConditionList.entry(for: $0)?.displayName
        }
        set(summaryNames.joined(separator: " · "), key: StorageKeys.Defaults.conditionsSummary(for: id))
    }

    private static func loadNonSensitive(id: UUID) -> NonSensitive? {
        let ud = UserDefaults.standard
        func get<T: Decodable>(_ type: T.Type, key: String) -> T? {
            guard let data = ud.data(forKey: key) else { return nil }
            return EncryptionManager.decrypt(type, from: data)
        }
        guard
            let displayName  = get(String.self,         key: StorageKeys.Defaults.displayName(for: id)),
            let dateOfBirth  = get(Date.self,            key: StorageKeys.Defaults.dateOfBirth(for: id)),
            let sex          = get(BiologicalSex.self,   key: StorageKeys.Defaults.biologicalSex(for: id)),
            let bloodType    = get(BloodType.self,       key: StorageKeys.Defaults.bloodType(for: id)),
            let dateCreated  = get(Date.self,            key: StorageKeys.Defaults.dateCreated(for: id)),
            let dateModified = get(Date.self,            key: StorageKeys.Defaults.dateModified(for: id))
        else { return nil }
        let lastUsed = get(Date.self, key: StorageKeys.Defaults.lastUsed(for: id)) ?? dateModified
        let conditionsSummary = get(String.self, key: StorageKeys.Defaults.conditionsSummary(for: id)) ?? ""
        return (displayName, dateOfBirth, sex, bloodType, dateCreated, dateModified, lastUsed, conditionsSummary)
    }

    private static func removeNonSensitive(id: UUID) {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: StorageKeys.Defaults.displayName(for: id))
        ud.removeObject(forKey: StorageKeys.Defaults.dateOfBirth(for: id))
        ud.removeObject(forKey: StorageKeys.Defaults.biologicalSex(for: id))
        ud.removeObject(forKey: StorageKeys.Defaults.bloodType(for: id))
        ud.removeObject(forKey: StorageKeys.Defaults.dateCreated(for: id))
        ud.removeObject(forKey: StorageKeys.Defaults.dateModified(for: id))
        ud.removeObject(forKey: StorageKeys.Defaults.lastUsed(for: id))
        ud.removeObject(forKey: StorageKeys.Defaults.conditionsSummary(for: id))
    }

    // MARK: - Sensitive (Keychain)

    private static func saveSensitive(_ profile: UserProfile) throws {
        let data = SensitiveProfileData(
            conditions: profile.conditions,
            conditionOtherNote: profile.conditionOtherNote,
            emergencyContactName: profile.emergencyContactName,
            emergencyContactPhone: profile.emergencyContactPhone
        )
        guard KeychainManager.save(data, for: StorageKeys.Keychain.sensitiveData(for: profile.id)) else {
            throw ProfileStoreError.saveFailed
        }
    }

    private static func loadSensitive(id: UUID) -> SensitiveProfileData? {
        KeychainManager.load(SensitiveProfileData.self, for: StorageKeys.Keychain.sensitiveData(for: id))
    }

    // MARK: - Assembly

    private static func assemble(id: UUID, non: NonSensitive, sensitive: SensitiveProfileData) -> UserProfile {
        var profile = UserProfile(
            displayName: non.displayName,
            dateOfBirth: non.dateOfBirth,
            biologicalSex: non.biologicalSex
        )
        profile.id = id
        profile.bloodType = non.bloodType
        profile.dateCreated = non.dateCreated
        profile.dateModified = non.dateModified
        profile.lastUsed = non.lastUsed
        profile.conditions = sensitive.conditions
        profile.conditionOtherNote = sensitive.conditionOtherNote
        profile.medications = MedicationStore.load(profileId: id)
        profile.allergies = AllergyStore.load(profileId: id)
        profile.emergencyContactName = sensitive.emergencyContactName
        profile.emergencyContactPhone = sensitive.emergencyContactPhone
        return profile
    }

    // MARK: - Helpers

    private static func ageGroup(from dob: Date) -> AgeGroup {
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        switch age {
        case ..<2:    return .infant
        case 2..<13:  return .child
        case 13..<65: return .adult
        default:      return .elderly
        }
    }
}
