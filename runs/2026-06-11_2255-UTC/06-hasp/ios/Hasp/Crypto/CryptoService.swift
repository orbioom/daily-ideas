import Foundation
import CryptoKit
import CommonCrypto

/// Vault cryptography: PBKDF2-HMAC-SHA256 key stretching (600k rounds,
/// OWASP-recommended order of magnitude) + AES-256-GCM authenticated
/// encryption via CryptoKit.
enum CryptoService {
    static let kdfRounds: UInt32 = 600_000
    static let keyLength = 32

    enum CryptoError: LocalizedError {
        case keyDerivationFailed
        case sealFailed
        case openFailed

        var errorDescription: String? {
            switch self {
            case .keyDerivationFailed: return "The encryption key could not be derived."
            case .sealFailed: return "The vault could not be encrypted."
            case .openFailed: return "The vault could not be decrypted with that passcode."
            }
        }
    }

    static func randomSalt(length: Int = 16) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        for i in 0..<length { bytes[i] = UInt8.random(in: 0...255) }
        return Data(bytes)
    }

    /// PBKDF2-HMAC-SHA256.
    static func deriveKey(passcode: String, salt: Data, rounds: UInt32 = kdfRounds) throws -> SymmetricKey {
        let passwordData = Data(passcode.utf8)
        var derived = [UInt8](repeating: 0, count: keyLength)

        let status = passwordData.withUnsafeBytes { passwordBytes -> Int32 in
            salt.withUnsafeBytes { saltBytes -> Int32 in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.bindMemory(to: Int8.self).baseAddress,
                    passwordData.count,
                    saltBytes.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    rounds,
                    &derived,
                    keyLength
                )
            }
        }
        guard status == kCCSuccess else { throw CryptoError.keyDerivationFailed }
        return SymmetricKey(data: Data(derived))
    }

    static func seal(_ plaintext: Data, key: SymmetricKey) throws -> Data {
        do {
            let box = try AES.GCM.seal(plaintext, using: key)
            guard let combined = box.combined else { throw CryptoError.sealFailed }
            return combined
        } catch {
            throw CryptoError.sealFailed
        }
    }

    static func open(_ combined: Data, key: SymmetricKey) throws -> Data {
        do {
            let box = try AES.GCM.SealedBox(combined: combined)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw CryptoError.openFailed
        }
    }
}
