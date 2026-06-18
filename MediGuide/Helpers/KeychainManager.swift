import Foundation
import Security
import LocalAuthentication

enum KeychainManager {

    private static let service = "com.mediguide"

    // MARK: - Biometric-Protected Save

    /// Saves data requiring biometric (or passcode) authentication before it can be read.
    @discardableResult
    static func saveBiometricProtected(_ data: Data, for key: String) -> Bool {
        delete(for: key)
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .userPresence,
            nil
        ) else { return false }
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     key,
            kSecValueData:       data,
            kSecAttrAccessControl: access
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Loads a biometric-protected item. iOS will prompt for biometrics automatically.
    static func loadBiometricProtected(for key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass:              kSecClassGenericPassword,
            kSecAttrService:        service,
            kSecAttrAccount:        key,
            kSecReturnData:         true,
            kSecMatchLimit:         kSecMatchLimitOne,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIAllow
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func saveBiometricProtected<T: Encodable>(_ value: T, for key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return saveBiometricProtected(data, for: key)
    }

    static func loadBiometricProtected<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        guard let data = loadBiometricProtected(for: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Reconfigure (for privacy enable/disable flow)

    /// Migrates an existing Keychain entry to require biometric authentication.
    @discardableResult
    static func reconfigureToBiometricProtected(key: String) -> Bool {
        guard let data = load(for: key) else { return true }
        return saveBiometricProtected(data, for: key)
    }

    /// Migrates an existing biometric-protected Keychain entry back to standard access.
    @discardableResult
    static func reconfigureToStandard(key: String) -> Bool {
        guard let data = loadBiometricProtected(for: key) else { return true }
        return save(data, for: key)
    }

    // MARK: - Core Data Operations

    @discardableResult
    static func save(_ data: Data, for key: String) -> Bool {
        delete(for: key)
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecValueData:        data,
            kSecAttrAccessible:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func load(for key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func update(_ data: Data, for key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound { return save(data, for: key) }
        return status == errSecSuccess
    }

    @discardableResult
    static func delete(for key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func exists(for key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Codable Convenience

    @discardableResult
    static func save<T: Encodable>(_ value: T, for key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return save(data, for: key)
    }

    static func load<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        guard let data = load(for: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
