import Foundation

enum PasswordGenerator {
    struct Options {
        var length: Int = 20
        var lowercase = true
        var uppercase = true
        var digits = true
        var symbols = true
        var excludeAmbiguous = true
    }

    private static let lower = "abcdefghijklmnopqrstuvwxyz"
    private static let upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private static let digitChars = "0123456789"
    private static let symbolChars = "!@#$%^&*()-_=+[]{}:;,.?/"
    private static let ambiguous: Set<Character> = ["l", "I", "1", "O", "0", "o"]

    static func generate(_ options: Options) -> String {
        var pools: [String] = []
        if options.lowercase { pools.append(lower) }
        if options.uppercase { pools.append(upper) }
        if options.digits { pools.append(digitChars) }
        if options.symbols { pools.append(symbolChars) }
        guard !pools.isEmpty else { return "" }

        let filter: (Character) -> Bool = { ch in
            !(options.excludeAmbiguous && ambiguous.contains(ch))
        }
        let filteredPools = pools.map { String($0.filter(filter)) }.filter { !$0.isEmpty }
        guard !filteredPools.isEmpty else { return "" }
        let all = filteredPools.joined()

        let length = max(6, min(64, options.length))
        // Guarantee one character from each enabled pool, fill the rest from
        // the union, then shuffle.
        var chars: [Character] = filteredPools.compactMap { $0.randomElement() }
        while chars.count < length {
            if let c = all.randomElement() { chars.append(c) }
        }
        return String(chars.prefix(length).shuffled())
    }

    /// Naive entropy estimate in bits: length × log2(pool size).
    static func entropyBits(for password: String) -> Double {
        guard !password.isEmpty else { return 0 }
        var pool = 0
        if password.contains(where: { $0.isLowercase }) { pool += 26 }
        if password.contains(where: { $0.isUppercase }) { pool += 26 }
        if password.contains(where: { $0.isNumber }) { pool += 10 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { pool += 24 }
        guard pool > 0 else { return 0 }
        return Double(password.count) * log2(Double(pool))
    }

    static func strengthLabel(bits: Double) -> (label: String, fraction: Double) {
        switch bits {
        case ..<40: return ("Weak", 0.25)
        case ..<60: return ("Okay", 0.5)
        case ..<90: return ("Strong", 0.75)
        default: return ("Excellent", 1.0)
        }
    }
}
