import Foundation

enum APICredentialManager {
    private static let keychainKey = "mediguide.api.claudeKey"

    /// Returns the API key from Keychain, falling back to an Info.plist value for development.
    /// The Info.plist key CLAUDE_API_KEY is set via xcconfig and is never committed to source.
    static func apiKey() -> String? {
        if let data = KeychainManager.load(for: keychainKey),
           let key = String(data: data, encoding: .utf8), !key.isEmpty {
            return key
        }
        return Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String
    }

    /// Stores the API key in Keychain. Call this once during initial setup or key rotation.
    @discardableResult
    static func storeKey(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        return KeychainManager.save(data, for: keychainKey)
    }

    static func clearKey() {
        KeychainManager.delete(for: keychainKey)
    }

    static var hasKey: Bool { apiKey() != nil }
}
