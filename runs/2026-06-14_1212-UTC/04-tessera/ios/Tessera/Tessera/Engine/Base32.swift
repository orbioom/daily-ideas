import Foundation

/// RFC 4648 Base32 (the standard alphabet used by every TOTP/HOTP provider).
///
/// Decode is tolerant of the things real-world secrets contain: lowercase letters,
/// spaces, and missing or present `=` padding. It returns `nil` on any character
/// outside the alphabet so callers never feed garbage into the HMAC.
enum Base32 {
    /// RFC 4648 alphabet: A–Z then 2–7.
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    /// Reverse lookup table: ASCII value → 5-bit value, or `nil` if not in the alphabet.
    private static let decodeMap: [Character: UInt8] = {
        var map: [Character: UInt8] = [:]
        for (index, char) in alphabet.enumerated() {
            map[char] = UInt8(index)
        }
        return map
    }()

    /// Decode a Base32 string into bytes. Spaces are ignored, case is normalized,
    /// and trailing `=` padding is allowed but not required. Returns `nil` if any
    /// non-padding character is outside the Base32 alphabet, or the bit pattern is
    /// invalid (e.g. a partial group that can't form whole bytes).
    static func decode(_ input: String) -> Data? {
        // Normalize: uppercase, strip spaces and dashes, drop padding.
        var cleaned = ""
        cleaned.reserveCapacity(input.count)
        for scalar in input.uppercased().unicodeScalars {
            let ch = Character(scalar)
            if ch == " " || ch == "-" || ch == "\t" || ch == "\n" || ch == "\r" { continue }
            if ch == "=" { continue } // padding — positional padding is implied by length
            cleaned.append(ch)
        }
        if cleaned.isEmpty { return nil }

        var output = [UInt8]()
        output.reserveCapacity(cleaned.count * 5 / 8)

        var buffer: UInt32 = 0   // accumulates up to 12 meaningful bits at a time
        var bitsInBuffer = 0     // number of valid bits currently held in `buffer`

        for char in cleaned {
            guard let value = decodeMap[char] else { return nil }
            buffer = (buffer << 5) | UInt32(value)
            bitsInBuffer += 5
            if bitsInBuffer >= 8 {
                bitsInBuffer -= 8
                let byte = UInt8((buffer >> UInt32(bitsInBuffer)) & 0xFF)
                output.append(byte)
            }
        }

        // Any leftover bits (< 8) must be zero — otherwise the input was malformed.
        if bitsInBuffer > 0 {
            let mask = UInt32((1 << bitsInBuffer) - 1)
            if (buffer & mask) != 0 { return nil }
        }

        if output.isEmpty { return nil }
        return Data(output)
    }

    /// Encode bytes to Base32 with standard `=` padding (used for export).
    static func encode(_ data: Data) -> String {
        if data.isEmpty { return "" }
        var result = ""
        var buffer: UInt32 = 0
        var bitsInBuffer = 0

        for byte in data {
            buffer = (buffer << 8) | UInt32(byte)
            bitsInBuffer += 8
            while bitsInBuffer >= 5 {
                bitsInBuffer -= 5
                let index = Int((buffer >> UInt32(bitsInBuffer)) & 0x1F)
                if index >= 0 && index < alphabet.count {
                    result.append(alphabet[index])
                }
            }
        }

        // Flush remaining bits (left-aligned into a final 5-bit group).
        if bitsInBuffer > 0 {
            let index = Int((buffer << UInt32(5 - bitsInBuffer)) & 0x1F)
            if index >= 0 && index < alphabet.count {
                result.append(alphabet[index])
            }
        }

        // Pad to a multiple of 8 characters per RFC 4648.
        let remainder = result.count % 8
        if remainder != 0 {
            result.append(String(repeating: "=", count: 8 - remainder))
        }
        return result
    }

    /// Lightweight validity check used by the manual-entry form (ignores padding/case/spaces).
    static func isValid(_ input: String) -> Bool {
        decode(input) != nil
    }
}
