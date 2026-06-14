import Foundation

/// The HMAC hash function backing an OTP. SHA1 is the RFC 6238 default.
enum OTPAlgorithm: String, CaseIterable, Identifiable, Codable {
    case sha1
    case sha256
    case sha512

    var id: String { rawValue }

    /// Display label as used by `otpauth://` URIs (uppercase).
    var uriValue: String {
        switch self {
        case .sha1: return "SHA1"
        case .sha256: return "SHA256"
        case .sha512: return "SHA512"
        }
    }

    var displayName: String { uriValue }

    /// Parse from an `otpauth://` `algorithm` query value (case-insensitive). Defaults to SHA1.
    static func from(uriValue: String?) -> OTPAlgorithm {
        switch uriValue?.uppercased() {
        case "SHA256": return .sha256
        case "SHA512": return .sha512
        default: return .sha1
        }
    }
}

/// TOTP (time-based) vs HOTP (counter-based).
enum OTPType: String, CaseIterable, Identifiable, Codable {
    case totp
    case hotp

    var id: String { rawValue }

    var uriValue: String { rawValue } // "totp" / "hotp"

    var displayName: String {
        switch self {
        case .totp: return "Time-based (TOTP)"
        case .hotp: return "Counter-based (HOTP)"
        }
    }

    var shortName: String {
        switch self {
        case .totp: return "TOTP"
        case .hotp: return "HOTP"
        }
    }

    static func from(host: String?) -> OTPType {
        host?.lowercased() == "hotp" ? .hotp : .totp
    }
}
