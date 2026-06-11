import Foundation
import Security
import CryptoKit

/// Stores the derived vault key in the iOS Keychain (this-device-only,
/// available only while unlocked) so Face ID / Touch ID can open the vault
/// without retyping the master passcode.
enum KeychainService {
    private static let service = "com.orbioom.hasp.vaultkey"
    private static let account = "derived-key"

    @discardableResult
    static func storeKey(_ key: SymmetricKey) -> Bool {
        let data = key.withUnsafeBytes { Data($0) }
        delete()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func loadKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data, data.count == CryptoService.keyLength else {
            return nil
        }
        return SymmetricKey(data: data)
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
