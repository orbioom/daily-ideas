import Foundation
import CryptoKit
import LocalAuthentication
import Observation

/// Owns the encrypted vault file and the in-memory decrypted copy.
/// On disk: JSON envelope { salt, rounds, blob } where blob is
/// AES-256-GCM(combined) of the vault JSON under the PBKDF2-derived key.
@MainActor
@Observable
final class VaultStore {
    enum LockState: Equatable {
        case noVault          // first run — needs a master passcode
        case locked
        case unlocked
    }

    private struct Envelope: Codable {
        var salt: Data
        var rounds: UInt32
        var blob: Data
    }

    private(set) var state: LockState = .noVault
    private(set) var vault = Vault()
    private(set) var lastError: String?
    private(set) var failedAttempts = 0

    private var key: SymmetricKey?
    private var salt: Data?

    var biometricsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricsEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "biometricsEnabled")
            if newValue, let key { KeychainService.storeKey(key) }
            if !newValue { KeychainService.delete() }
        }
    }

    static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("vault.hasp")
    }

    init() {
        state = FileManager.default.fileExists(atPath: Self.fileURL.path) ? .locked : .noVault
    }

    // MARK: - Setup / unlock / lock

    func createVault(passcode: String) {
        lastError = nil
        do {
            let newSalt = CryptoService.randomSalt()
            let newKey = try CryptoService.deriveKey(passcode: passcode, salt: newSalt)
            salt = newSalt
            key = newKey
            vault = Vault()
            try persist()
            state = .unlocked
        } catch {
            lastError = error.localizedDescription
        }
    }

    func unlock(passcode: String) -> Bool {
        lastError = nil
        do {
            let envelope = try loadEnvelope()
            let candidate = try CryptoService.deriveKey(passcode: passcode,
                                                        salt: envelope.salt,
                                                        rounds: envelope.rounds)
            let plain = try CryptoService.open(envelope.blob, key: candidate)
            vault = try JSONDecoder().decode(Vault.self, from: plain)
            key = candidate
            salt = envelope.salt
            failedAttempts = 0
            if biometricsEnabled { KeychainService.storeKey(candidate) }
            state = .unlocked
            return true
        } catch {
            failedAttempts += 1
            lastError = "Wrong passcode. The vault stays sealed."
            return false
        }
    }

    /// Face ID / Touch ID unlock using the key cached in the Keychain.
    func unlockWithBiometrics() async -> Bool {
        lastError = nil
        guard biometricsEnabled, KeychainService.loadKey() != nil else { return false }
        let context = LAContext()
        var policyError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &policyError) else {
            lastError = "Biometrics aren't available on this device right now."
            return false
        }
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock your Hasp vault"
            )
            guard ok, let cached = KeychainService.loadKey() else { return false }
            let envelope = try loadEnvelope()
            let plain = try CryptoService.open(envelope.blob, key: cached)
            vault = try JSONDecoder().decode(Vault.self, from: plain)
            key = cached
            salt = envelope.salt
            failedAttempts = 0
            state = .unlocked
            return true
        } catch {
            // User cancelled or the cached key no longer matches.
            return false
        }
    }

    func lock() {
        key = nil
        vault = Vault()
        if state == .unlocked { state = .locked }
    }

    func changePasscode(current: String, new: String) -> Bool {
        lastError = nil
        do {
            let envelope = try loadEnvelope()
            let oldKey = try CryptoService.deriveKey(passcode: current,
                                                     salt: envelope.salt,
                                                     rounds: envelope.rounds)
            let plain = try CryptoService.open(envelope.blob, key: oldKey)
            let decoded = try JSONDecoder().decode(Vault.self, from: plain)

            let newSalt = CryptoService.randomSalt()
            let newKey = try CryptoService.deriveKey(passcode: new, salt: newSalt)
            vault = decoded
            salt = newSalt
            key = newKey
            try persist()
            if biometricsEnabled { KeychainService.storeKey(newKey) }
            return true
        } catch {
            lastError = "The current passcode didn't match."
            return false
        }
    }

    // MARK: - Item CRUD (auto-persisting)

    func upsert(_ item: VaultItem) {
        var updated = item
        updated.updatedAt = .now
        if let index = vault.items.firstIndex(where: { $0.id == item.id }) {
            vault.items[index] = updated
        } else {
            vault.items.append(updated)
        }
        save()
    }

    func delete(_ item: VaultItem) {
        vault.items.removeAll { $0.id == item.id }
        save()
    }

    func toggleFavorite(_ item: VaultItem) {
        if let index = vault.items.firstIndex(where: { $0.id == item.id }) {
            vault.items[index].isFavorite.toggle()
            vault.items[index].updatedAt = .now
            save()
        }
    }

    private func save() {
        do {
            try persist()
            lastError = nil
        } catch {
            lastError = "Saving failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Disk

    private func loadEnvelope() throws -> Envelope {
        let data = try Data(contentsOf: Self.fileURL)
        return try JSONDecoder().decode(Envelope.self, from: data)
    }

    private func persist() throws {
        guard let key, let salt else { throw CryptoService.CryptoError.sealFailed }
        let plain = try JSONEncoder().encode(vault)
        let blob = try CryptoService.seal(plain, key: key)
        let envelope = Envelope(salt: salt, rounds: CryptoService.kdfRounds, blob: blob)
        let data = try JSONEncoder().encode(envelope)
        try data.write(to: Self.fileURL, options: [.atomic, .completeFileProtection])
    }
}
