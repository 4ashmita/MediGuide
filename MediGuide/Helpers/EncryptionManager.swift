import Foundation
import CryptoKit

enum EncryptionManager {

    // MARK: - Key management

    private static var symmetricKey: SymmetricKey {
        if let data = KeychainManager.load(for: StorageKeys.Keychain.encryptionMasterKey),
           data.count == 32 {
            return SymmetricKey(data: data)
        }
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        KeychainManager.save(keyData, for: StorageKeys.Keychain.encryptionMasterKey)
        return newKey
    }

    // MARK: - Encrypt / Decrypt

    static func encrypt(_ data: Data) -> Data? {
        guard let sealedBox = try? AES.GCM.seal(data, using: symmetricKey) else { return nil }
        return sealedBox.combined
    }

    static func decrypt(_ data: Data) -> Data? {
        guard let sealedBox = try? AES.GCM.SealedBox(combined: data),
              let decrypted = try? AES.GCM.open(sealedBox, using: symmetricKey) else { return nil }
        return decrypted
    }

    // MARK: - Codable Convenience

    static func encrypt<T: Encodable>(_ value: T) -> Data? {
        guard let encoded = try? JSONEncoder().encode(value) else { return nil }
        return encrypt(encoded)
    }

    static func decrypt<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        guard let decrypted = decrypt(data) else { return nil }
        return try? JSONDecoder().decode(type, from: decrypted)
    }
}
