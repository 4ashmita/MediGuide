import Foundation
import Security

enum ProfileStoreError: Error {
    case encodingFailed
    case keychainWriteFailed(OSStatus)
    case keychainReadFailed(OSStatus)
    case decodingFailed
}

enum ProfileStore {

    private static let keychainService = "com.mediguide.profiles"
    private static let profilesKey = "stored_profiles"
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Save

    static func save(_ profile: UserProfile) throws {
        var profiles = loadAll()
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updated = profile
            updated.dateModified = Date()
            profiles[idx] = updated
        } else {
            profiles.append(profile)
        }
        try persist(profiles)
        OnboardingManager.markProfileCreated()
    }

    // MARK: - Load

    static func loadAll() -> [UserProfile] {
        guard let data = keychainRead() else { return [] }
        return (try? decoder.decode([UserProfile].self, from: data)) ?? []
    }

    static func load(id: UUID) -> UserProfile? {
        loadAll().first { $0.id == id }
    }

    // MARK: - Delete

    static func delete(id: UUID) {
        var profiles = loadAll()
        profiles.removeAll { $0.id == id }
        try? persist(profiles)
        if profiles.isEmpty {
            OnboardingManager.resetProfileCreated()
        }
    }

    // MARK: - Keychain

    private static func persist(_ profiles: [UserProfile]) throws {
        guard let data = try? encoder.encode(profiles) else { throw ProfileStoreError.encodingFailed }
        let status = keychainWrite(data)
        if status != errSecSuccess { throw ProfileStoreError.keychainWriteFailed(status) }
    }

    @discardableResult
    private static func keychainWrite(_ data: Data) -> OSStatus {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: profilesKey
        ]
        SecItemDelete(query as CFDictionary)

        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: profilesKey,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        return SecItemAdd(attributes as CFDictionary, nil)
    }

    private static func keychainRead() -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: profilesKey,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}
