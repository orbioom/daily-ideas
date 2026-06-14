import Foundation

/// Scales human ingredient amounts that begin with a number (incl. simple
/// fractions like "1/2" or mixed "1 1/2"). Anything else is returned unchanged.
enum AmountScaler {

    /// Scale `amount` by `factor`. Pure & guarded.
    static func scale(_ amount: String, factor: Double) -> String {
        guard factor > 0 else { return amount }
        let trimmed = amount.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return amount }

        // Pull the leading numeric token (supports "1", "1.5", "1/2", "1 1/2").
        guard let value = leadingNumber(in: trimmed) else { return amount }
        let scaled = value.value * factor
        let remainder = String(trimmed.dropFirst(value.length))
            .trimmingCharacters(in: .whitespaces)

        let numberText = format(scaled)
        return remainder.isEmpty ? numberText : "\(numberText) \(remainder)"
    }

    private struct LeadingNumber { let value: Double; let length: Int }

    /// Parses a leading number that may be whole, decimal, fraction, or mixed.
    private static func leadingNumber(in s: String) -> LeadingNumber? {
        let chars = Array(s)
        var i = 0

        func readUnsignedNumber() -> (Double, Int)? {
            var j = i
            var sawDigit = false
            while j < chars.count, chars[j].isNumber { j += 1; sawDigit = true }
            if j < chars.count, chars[j] == "." {
                j += 1
                while j < chars.count, chars[j].isNumber { j += 1; sawDigit = true }
            }
            guard sawDigit else { return nil }
            let token = String(chars[i..<j])
            guard let v = Double(token) else { return nil }
            return (v, j)
        }

        guard let first = readUnsignedNumber() else { return nil }
        var total = first.0
        i = first.1
        var consumed = i

        // Optional fraction: "/2" directly, or " 1/2" mixed number.
        // Case A: immediate slash → it's a fraction like "1/2".
        if i < chars.count, chars[i] == "/" {
            i += 1
            if let denom = readUnsignedNumber(), denom.0 != 0 {
                total = first.0 / denom.0
                i = denom.1
                consumed = i
                return LeadingNumber(value: total, length: consumed)
            }
            return LeadingNumber(value: total, length: consumed)
        }

        // Case B: space then another number with slash → mixed "1 1/2".
        var k = i
        while k < chars.count, chars[k] == " " { k += 1 }
        if k < chars.count, chars[k].isNumber {
            let saveI = i
            i = k
            if let whole2 = readUnsignedNumber() {
                if i < chars.count, chars[i] == "/" {
                    i += 1
                    if let denom = readUnsignedNumber(), denom.0 != 0 {
                        total = first.0 + (whole2.0 / denom.0)
                        consumed = denom.1
                        return LeadingNumber(value: total, length: consumed)
                    }
                }
            }
            i = saveI
        }

        return LeadingNumber(value: total, length: consumed)
    }

    /// Format a scaled number cleanly (whole when possible, else up to 2 decimals).
    private static func format(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value.rounded()))
        }
        let rounded = (value * 100).rounded() / 100
        var text = String(format: "%.2f", rounded)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }
}
