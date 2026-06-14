import Foundation
import SwiftData

/// A single 2FA account (one OTP secret). Persisted via SwiftData.
///
/// Storage note: the Base32 secret is stored as-is. In this build, protection is
/// provided by the on-device app-lock (Face ID / Touch ID) plus iOS Data
/// Protection (Keychain-class file encryption tied to the passcode), not by an
/// extra application-layer cipher. This is documented honestly in the README.
@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var issuer: String          // e.g. "GitHub"
    var label: String           // account name, e.g. "ada@work.com"
    var secretBase32: String    // the shared secret (Base32)
    var algorithmRaw: String    // sha1 / sha256 / sha512
    var digits: Int             // 6 / 7 / 8
    var period: Int             // TOTP step seconds (default 30)
    var typeRaw: String         // totp / hotp
    var counter: Int            // HOTP moving factor
    var colorHue: Double        // 0...1 avatar hue
    var sortIndex: Int          // manual ordering
    var favorite: Bool
    var createdAt: Date

    var folder: Folder?

    init(issuer: String,
         label: String,
         secretBase32: String,
         algorithm: OTPAlgorithm = .sha1,
         digits: Int = 6,
         period: Int = 30,
         type: OTPType = .totp,
         counter: Int = 0,
         colorHue: Double = 0.62,
         sortIndex: Int = 0,
         favorite: Bool = false,
         createdAt: Date = .now,
         folder: Folder? = nil) {
        self.id = UUID()
        self.issuer = issuer
        self.label = label
        self.secretBase32 = secretBase32
        self.algorithmRaw = algorithm.rawValue
        self.digits = OTPGenerator.clampDigits(digits)
        self.period = max(period, 1)
        self.typeRaw = type.rawValue
        self.counter = max(counter, 0)
        self.colorHue = min(max(colorHue, 0), 1)
        self.sortIndex = sortIndex
        self.favorite = favorite
        self.createdAt = createdAt
        self.folder = folder
    }

    // MARK: - Typed accessors (enums stored as raw strings for SwiftData stability)

    var algorithm: OTPAlgorithm {
        get { OTPAlgorithm(rawValue: algorithmRaw) ?? .sha1 }
        set { algorithmRaw = newValue.rawValue }
    }

    var type: OTPType {
        get { OTPType(rawValue: typeRaw) ?? .totp }
        set { typeRaw = newValue.rawValue }
    }

    // MARK: - Derived display

    /// Decoded secret bytes, or nil if the stored secret is somehow invalid.
    var decodedSecret: Data? {
        Base32.decode(secretBase32)
    }

    /// A readable title: prefers issuer, falls back to label.
    var displayTitle: String {
        issuer.isEmpty ? label : issuer
    }

    /// Subtitle under the title (the account/email when an issuer exists).
    var displaySubtitle: String {
        issuer.isEmpty ? "" : label
    }

    /// Two-letter monogram for the avatar.
    var monogram: String {
        let source = displayTitle.trimmingCharacters(in: .whitespaces)
        guard let first = source.first else { return "?" }
        return String(first).uppercased()
    }

    /// Build an `otpauth://` URI representation for export / QR.
    func authURI() -> OTPAuthURI {
        OTPAuthURI(type: type,
                   issuer: issuer,
                   accountName: label,
                   secretBase32: secretBase32,
                   algorithm: algorithm,
                   digits: digits,
                   period: period,
                   counter: counter)
    }
}
