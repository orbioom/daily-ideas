import Foundation
import CryptoKit

/// Pure, UI-free implementation of RFC 4226 (HOTP) and RFC 6238 (TOTP).
///
/// All paths are total: every input that could fail (bad Base32, out-of-range
/// digits) yields `nil` rather than crashing. There are no force-unwraps and no
/// `try!` here. Verified by hand against the RFC 6238 reference vectors.
enum OTPGenerator {

    /// Clamp digit count to the RFC-permitted 6/7/8 window.
    static func clampDigits(_ d: Int) -> Int {
        min(max(d, 6), 8)
    }

    /// RFC 4226 §5.3 — HMAC-SHA-X over an 8-byte big-endian counter, then
    /// dynamic truncation to a `digits`-long, zero-padded decimal string.
    ///
    /// - Parameters:
    ///   - secret: the raw (already Base32-decoded) shared secret.
    ///   - counter: the moving factor (time-step for TOTP, event count for HOTP).
    ///   - digits: 6, 7, or 8.
    ///   - algorithm: SHA1 (default), SHA256, or SHA512.
    /// - Returns: a zero-padded code, or `nil` if the secret is empty.
    static func code(secret: Data,
                     counter: UInt64,
                     digits: Int,
                     algorithm: OTPAlgorithm) -> String? {
        guard !secret.isEmpty else { return nil }

        // 8-byte big-endian representation of the counter (RFC 4226 §5.2).
        // Built byte-by-byte so the result is guaranteed to be exactly 8 bytes,
        // independent of platform endianness, with no crash path.
        var counterBytes = Data(count: 8)
        for i in 0..<8 {
            let shift = UInt64((7 - i) * 8)
            counterBytes[i] = UInt8((counter >> shift) & 0xFF)
        }

        let key = SymmetricKey(data: secret)
        let hmac: Data
        switch algorithm {
        case .sha1:
            let mac = HMAC<Insecure.SHA1>.authenticationCode(for: counterBytes, using: key)
            hmac = Data(mac)
        case .sha256:
            let mac = HMAC<SHA256>.authenticationCode(for: counterBytes, using: key)
            hmac = Data(mac)
        case .sha512:
            let mac = HMAC<SHA512>.authenticationCode(for: counterBytes, using: key)
            hmac = Data(mac)
        }

        return truncate(hmac: hmac, digits: digits)
    }

    /// RFC 4226 §5.3 dynamic truncation. Extracts a 31-bit value at the offset
    /// encoded in the low nibble of the last HMAC byte, then reduces mod 10^digits.
    private static func truncate(hmac: Data, digits: Int) -> String? {
        let bytes = [UInt8](hmac)
        // SHA1 → 20, SHA256 → 32, SHA512 → 64. We need at least an offset byte plus 4.
        guard bytes.count >= 20 else { return nil }

        // Low 4 bits of the final byte give the offset (0...15 for SHA1; always valid
        // because offset+3 <= 15+3 = 18 < 20 <= bytes.count).
        let lastIndex = bytes.count - 1
        let offset = Int(bytes[lastIndex] & 0x0F)
        guard offset >= 0, offset + 3 < bytes.count else { return nil }

        let b0 = UInt32(bytes[offset]     & 0x7F) << 24   // mask top bit per RFC
        let b1 = UInt32(bytes[offset + 1] & 0xFF) << 16
        let b2 = UInt32(bytes[offset + 2] & 0xFF) << 8
        let b3 = UInt32(bytes[offset + 3] & 0xFF)
        let binary = b0 | b1 | b2 | b3

        let clamped = clampDigits(digits)
        let modulus = pow10(clamped)
        let otp = binary % modulus

        // Zero-pad to the requested width.
        var str = String(otp)
        if str.count < clamped {
            str = String(repeating: "0", count: clamped - str.count) + str
        }
        return str
    }

    /// Integer powers of ten for digit widths 6...8 (no overflow risk).
    private static func pow10(_ exp: Int) -> UInt32 {
        var result: UInt32 = 1
        for _ in 0..<max(exp, 0) { result *= 10 }
        return result
    }

    // MARK: - TOTP convenience

    /// Time-step counter for TOTP: floor(unixTime / period). Period is guarded > 0.
    static func timeCounter(unixTime: TimeInterval, period: Int) -> UInt64 {
        let p = max(period, 1)
        let steps = floor(unixTime / Double(p))
        if steps < 0 { return 0 }
        return UInt64(steps)
    }

    /// Seconds remaining in the current TOTP window (1...period).
    static func secondsRemaining(unixTime: TimeInterval, period: Int) -> Int {
        let p = max(period, 1)
        let elapsed = Int(floor(unixTime).truncatingRemainder(dividingBy: Double(p)))
        let remaining = p - (elapsed % p)
        return remaining == 0 ? p : remaining
    }

    /// Fraction of the current window already elapsed (0 → fresh, →1 → about to roll).
    static func progress(unixTime: TimeInterval, period: Int) -> Double {
        let p = Double(max(period, 1))
        let elapsed = unixTime.truncatingRemainder(dividingBy: p)
        let frac = elapsed / p
        return min(max(frac, 0), 1)
    }

    /// Generate the current TOTP for an already-decoded secret.
    static func totp(secret: Data,
                     digits: Int,
                     period: Int,
                     algorithm: OTPAlgorithm,
                     at date: Date = .now) -> String? {
        let counter = timeCounter(unixTime: date.timeIntervalSince1970, period: period)
        return code(secret: secret, counter: counter, digits: digits, algorithm: algorithm)
    }

    /// Generate the HOTP for a specific event counter.
    static func hotp(secret: Data,
                     counter: Int,
                     digits: Int,
                     algorithm: OTPAlgorithm) -> String? {
        let c = UInt64(max(counter, 0))
        return code(secret: secret, counter: c, digits: digits, algorithm: algorithm)
    }

    // MARK: - Formatting

    /// Group a code for legibility: "123 456" (6), "123 4567" (7→3+4), "1234 5678" (8).
    static func grouped(_ code: String) -> String {
        let chars = Array(code)
        switch chars.count {
        case 6:
            return String(chars[0..<3]) + " " + String(chars[3..<6])
        case 7:
            return String(chars[0..<3]) + " " + String(chars[3..<7])
        case 8:
            return String(chars[0..<4]) + " " + String(chars[4..<8])
        default:
            // Fallback: split into halves, guarding the midpoint.
            guard chars.count > 1 else { return code }
            let mid = chars.count / 2
            return String(chars[0..<mid]) + " " + String(chars[mid...])
        }
    }
}
