import Foundation

/// Selectable integer width for the programmer calculator.
enum BitWidth: Int, CaseIterable, Identifiable {
    case eight = 8, sixteen = 16, thirtyTwo = 32, sixtyFour = 64
    var id: Int { rawValue }
    var label: String { "\(rawValue)" }

    /// Mask of valid bits for this width (within a UInt64 carrier).
    var mask: UInt64 {
        rawValue == 64 ? UInt64.max : (UInt64(1) << UInt64(rawValue)) - 1
    }
}

/// Numeric base for parsing/formatting.
enum NumberBase: Int, CaseIterable, Identifiable {
    case dec = 10, hex = 16, bin = 2, oct = 8
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .dec: return "DEC"
        case .hex: return "HEX"
        case .bin: return "BIN"
        case .oct: return "OCT"
        }
    }
}

/// Pure programmer-calculator engine using fixed-width unsigned integer logic.
/// All values are carried as `UInt64` and masked to the active `BitWidth`, so
/// overflow wraps consistently within the chosen width (documented behavior).
enum BaseConverter {

    /// Parses a string in the given base into a width-masked UInt64.
    /// Returns nil if any character is invalid for that base.
    static func parse(_ raw: String, base: NumberBase, width: BitWidth) -> UInt64? {
        let cleaned = raw.uppercased().filter { !$0.isWhitespace }
        guard !cleaned.isEmpty else { return 0 }
        let digits = "0123456789ABCDEF"
        let radix = UInt64(base.rawValue)
        var value: UInt64 = 0
        for ch in cleaned {
            guard let pos = digits.firstIndex(of: ch) else { return nil }
            let digitValue = UInt64(digits.distance(from: digits.startIndex, to: pos))
            guard digitValue < radix else { return nil }
            // Detect carrier overflow before it happens; otherwise mask to width.
            let (mulled, mulOverflow) = value.multipliedReportingOverflow(by: radix)
            if mulOverflow { return nil }
            let (added, addOverflow) = mulled.addingReportingOverflow(digitValue)
            if addOverflow { return nil }
            value = added
        }
        return value & width.mask
    }

    /// Formats a width-masked value into the given base.
    static func format(_ value: UInt64, base: NumberBase, width: BitWidth) -> String {
        let masked = value & width.mask
        switch base {
        case .dec:
            return String(masked, radix: 10)
        case .hex:
            return String(masked, radix: 16, uppercase: true)
        case .oct:
            return String(masked, radix: 8)
        case .bin:
            return String(masked, radix: 2)
        }
    }

    /// Binary representation grouped into nibbles for readability.
    static func groupedBinary(_ value: UInt64, width: BitWidth) -> String {
        let masked = value & width.mask
        var bits = String(masked, radix: 2)
        // Pad to the full width so leading zeros are visible.
        if bits.count < width.rawValue {
            bits = String(repeating: "0", count: width.rawValue - bits.count) + bits
        }
        var grouped = ""
        for (index, ch) in bits.enumerated() {
            if index != 0 && (bits.count - index) % 4 == 0 { grouped.append(" ") }
            grouped.append(ch)
        }
        return grouped
    }

    // MARK: Bitwise operations (all width-masked)

    static func and(_ a: UInt64, _ b: UInt64, width: BitWidth) -> UInt64 { (a & b) & width.mask }
    static func or(_ a: UInt64, _ b: UInt64, width: BitWidth) -> UInt64 { (a | b) & width.mask }
    static func xor(_ a: UInt64, _ b: UInt64, width: BitWidth) -> UInt64 { (a ^ b) & width.mask }
    static func not(_ a: UInt64, width: BitWidth) -> UInt64 { (~a) & width.mask }

    /// Logical left shift, masked to the active width (overflow bits drop off).
    static func shiftLeft(_ a: UInt64, by amount: Int, width: BitWidth) -> UInt64 {
        let n = max(0, min(amount, 63))
        return (a << UInt64(n)) & width.mask
    }

    /// Logical right shift within the active width.
    static func shiftRight(_ a: UInt64, by amount: Int, width: BitWidth) -> UInt64 {
        let n = max(0, min(amount, 63))
        return ((a & width.mask) >> UInt64(n)) & width.mask
    }

    /// Arithmetic add with width wrap (documented overflow behavior).
    static func add(_ a: UInt64, _ b: UInt64, width: BitWidth) -> UInt64 {
        a.addingReportingOverflow(b).partialValue & width.mask
    }
}
