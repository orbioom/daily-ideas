import Foundation

/// Hand-rolled EAN-13 / UPC-A encoder. This is Stash's showcase algorithm: it
/// computes/validates the check digit and builds the exact module bit pattern using
/// the L / G / R code tables and the first-digit parity pattern. The result is a
/// `[Bool]` where `true` is a dark module and `false` is a light module, which the
/// `EAN13BarcodeView` draws as crisp bars with a SwiftUI `Canvas`.
///
/// References (well-established public encoding tables, no licensing concerns):
/// - L-codes (odd parity), G-codes (even parity), R-codes (right side).
/// - The first digit selects an L/G pattern for the six left-hand digits.
enum EAN13Encoder {

    /// L-code (odd parity) module patterns for digits 0...9. Each is 7 modules.
    private static let lCodes: [[Bool]] = [
        [false, false, false, true,  true,  false, true ], // 0  0001101
        [false, false, true,  true,  false, false, true ], // 1  0011001
        [false, false, true,  false, false, true,  true ], // 2  0010011
        [false, true,  true,  true,  true,  false, true ], // 3  0111101
        [false, true,  false, false, false, true,  true ], // 4  0100011
        [false, true,  true,  false, false, false, true ], // 5  0110001
        [false, true,  false, true,  true,  true,  true ], // 6  0101111
        [false, true,  true,  true,  false, true,  true ], // 7  0111011
        [false, true,  true,  false, true,  true,  true ], // 8  0110111
        [false, false, false, true,  false, true,  true ]  // 9  0001011
    ]

    /// G-code (even parity) patterns: the reverse-bit mirror of the L-codes.
    private static let gCodes: [[Bool]] = [
        [false, true,  false, false, true,  true,  true ], // 0  0100111
        [false, true,  true,  false, false, true,  true ], // 1  0110011
        [false, false, true,  true,  false, true,  true ], // 2  0011011
        [false, true,  false, false, false, false, true ], // 3  0100001
        [false, false, true,  true,  true,  false, true ], // 4  0011101
        [false, true,  true,  true,  false, false, true ], // 5  0111001
        [false, false, false, false, true,  false, true ], // 6  0000101
        [false, false, true,  false, false, false, true ], // 7  0010001
        [false, false, false, true,  false, false, true ], // 8  0001001
        [false, false, true,  false, true,  true,  true ]  // 9  0010111
    ]

    /// First-digit parity patterns. `true` = use G-code, `false` = use L-code, for
    /// each of the six left-hand digits.
    private static let parityPatterns: [[Bool]] = [
        [false, false, false, false, false, false], // 0  LLLLLL
        [false, false, true,  false, true,  true ], // 1  LLGLGG
        [false, false, true,  true,  false, true ], // 2  LLGGLG
        [false, false, true,  true,  true,  false], // 3  LLGGGL
        [false, true,  false, false, true,  true ], // 4  LGLLGG
        [false, true,  true,  false, false, true ], // 5  LGGLLG
        [false, true,  true,  true,  false, false], // 6  LGGGLL
        [false, true,  false, true,  false, true ], // 7  LGLGLG
        [false, true,  false, true,  true,  false], // 8  LGLGGL
        [false, true,  true,  false, true,  false]  // 9  LGGLGL
    ]

    /// Parse a string into an array of digit values (0...9), rejecting non-digits.
    private static func digits(of value: String) -> [Int]? {
        let chars = value.trimmingCharacters(in: .whitespacesAndNewlines)
        var result: [Int] = []
        result.reserveCapacity(chars.count)
        for ch in chars {
            guard let d = ch.wholeNumberValue, (0...9).contains(d) else { return nil }
            result.append(d)
        }
        return result
    }

    /// Compute the EAN-13 check digit for the first 12 digits using the
    /// 1-3-1-3… weighting from the left.
    static func checkDigit(forFirst12 first12: [Int]) -> Int? {
        guard first12.count == 12 else { return nil }
        var sum = 0
        for (index, digit) in first12.enumerated() {
            // Odd positions (1-indexed) weight 1, even positions weight 3.
            sum += (index % 2 == 0) ? digit : digit * 3
        }
        let mod = sum % 10
        return mod == 0 ? 0 : 10 - mod
    }

    /// Normalize a user-supplied value to a valid 13-digit EAN-13 string, or return
    /// `nil` with a reason if it can't be encoded.
    /// Accepts:
    /// - 12 digits → appends a computed check digit.
    /// - 13 digits → validates the existing check digit.
    static func normalizedEAN13(from value: String) -> Result<String, BarcodeError> {
        guard let ds = digits(of: value) else {
            return .failure(.invalidCharacters)
        }
        switch ds.count {
        case 12:
            guard let check = checkDigit(forFirst12: ds) else {
                return .failure(.wrongLength(expected: "12 or 13 digits"))
            }
            return .success((ds + [check]).map(String.init).joined())
        case 13:
            let first12 = Array(ds.prefix(12))
            guard let check = checkDigit(forFirst12: first12) else {
                return .failure(.wrongLength(expected: "12 or 13 digits"))
            }
            guard check == ds[12] else {
                return .failure(.badCheckDigit)
            }
            return .success(ds.map(String.init).joined())
        default:
            return .failure(.wrongLength(expected: "12 or 13 digits"))
        }
    }

    /// Normalize a UPC-A value (11 or 12 digits) to its equivalent 13-digit EAN-13
    /// by prefixing a leading zero, reusing the EAN-13 path.
    static func normalizedUPCA(from value: String) -> Result<String, BarcodeError> {
        guard let ds = digits(of: value) else {
            return .failure(.invalidCharacters)
        }
        switch ds.count {
        case 11, 12:
            // UPC-A is EAN-13 with a leading 0. Build a 12-digit EAN base then encode.
            let padded = "0" + ds.map(String.init).joined()
            return normalizedEAN13(from: padded)
        default:
            return .failure(.wrongLength(expected: "11 or 12 digits"))
        }
    }

    /// Build the full 95-module bit pattern for a normalized 13-digit string.
    /// Returns `nil` if the input isn't exactly 13 valid digits.
    ///
    /// Layout: start guard (101) + 6 left digits (L/G by parity) + center guard
    /// (01010) + 6 right digits (R) + end guard (101) = 3 + 42 + 5 + 42 + 3 = 95.
    static func modules(forEAN13 normalized: String) -> [Bool]? {
        guard let ds = digits(of: normalized), ds.count == 13 else { return nil }
        let firstDigit = ds[0]
        guard (0...9).contains(firstDigit) else { return nil }
        let parity = parityPatterns[firstDigit]

        var bits: [Bool] = []
        bits.reserveCapacity(95)

        // Start guard 101.
        bits.append(contentsOf: [true, false, true])

        // Left six digits (positions 1...6), choosing L or G per the parity pattern.
        for i in 0..<6 {
            let digit = ds[i + 1]
            let useG = parity[i]
            bits.append(contentsOf: useG ? gCodes[digit] : lCodes[digit])
        }

        // Center guard 01010.
        bits.append(contentsOf: [false, true, false, true, false])

        // Right six digits (positions 7...12) use R-codes (the bit-inverse of L-codes).
        for i in 0..<6 {
            let digit = ds[i + 7]
            let rCode = lCodes[digit].map { !$0 }
            bits.append(contentsOf: rCode)
        }

        // End guard 101.
        bits.append(contentsOf: [true, false, true])

        return bits
    }

    /// True if guard bars (which extend slightly below the digit row in print) sit at
    /// this module index — used purely for the decorative long-bar styling.
    static func isGuardModule(_ index: Int) -> Bool {
        // Start 0...2, center 45...49, end 92...94 in the 95-module layout.
        (0...2).contains(index) || (45...49).contains(index) || (92...94).contains(index)
    }
}

/// Calm, recoverable error states surfaced when a value can't be encoded.
enum BarcodeError: Error, Equatable {
    case empty
    case invalidCharacters
    case wrongLength(expected: String)
    case badCheckDigit
    case renderFailed

    var message: String {
        switch self {
        case .empty:
            return "Enter a code value to generate a barcode."
        case .invalidCharacters:
            return "This format accepts digits only."
        case .wrongLength(let expected):
            return "This format needs \(expected)."
        case .badCheckDigit:
            return "The check digit doesn't match. Stash can fix it for you."
        case .renderFailed:
            return "Couldn't render this code. Try a different format."
        }
    }
}
