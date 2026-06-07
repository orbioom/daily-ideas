import Foundation

/// The outcome of rolling a dice expression.
struct RollResult {
    let expression: String
    let total: Int
    let breakdown: String   // human-readable, e.g. "2d6 [4, 5] + 3 = 12"
    let rolls: [Int]        // individual die faces, in order
}

/// A pure dice-notation parser and roller.
///
/// Supports sums and differences of terms, where each term is either a constant
/// or `NdM` (N dice with M sides), e.g. `2d6 + 1d4 + 3` or `1d20 - 1`.
enum Dice {

    /// Roll an expression. Returns nil if it can't be parsed or has no dice/const.
    static func roll<G: RandomNumberGenerator>(_ expression: String, using rng: inout G) -> RollResult? {
        let cleaned = expression.lowercased().replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }

        // Split into signed terms.
        var terms: [(sign: Int, body: String)] = []
        var current = ""
        var sign = 1
        for (i, ch) in cleaned.enumerated() {
            if ch == "+" || ch == "-" {
                if i == 0 { sign = (ch == "-") ? -1 : 1; continue }
                if !current.isEmpty { terms.append((sign, current)); current = "" }
                sign = (ch == "-") ? -1 : 1
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { terms.append((sign, current)) }
        guard !terms.isEmpty else { return nil }

        var total = 0
        var rolls: [Int] = []
        var parts: [String] = []
        var valid = false

        for term in terms {
            if term.body.contains("d") {
                let comps = term.body.split(separator: "d", omittingEmptySubsequences: false)
                guard comps.count == 2 else { return nil }
                let count = comps[0].isEmpty ? 1 : Int(comps[0])
                guard let n = count, let sides = Int(comps[1]), n > 0, n <= 999, sides >= 1, sides <= 1000 else {
                    return nil
                }
                var termRolls: [Int] = []
                for _ in 0..<n {
                    let face = Int.random(in: 1...sides, using: &rng)
                    termRolls.append(face)
                    rolls.append(face)
                }
                let sum = termRolls.reduce(0, +)
                total += term.sign * sum
                let listed = termRolls.map(String.init).joined(separator: ", ")
                parts.append("\(term.sign < 0 ? "−" : "")\(n)d\(sides) [\(listed)]")
                valid = true
            } else {
                guard let constant = Int(term.body) else { return nil }
                total += term.sign * constant
                parts.append("\(term.sign < 0 ? "−" : "")\(constant)")
                valid = true
            }
        }
        guard valid else { return nil }
        let breakdown = parts.joined(separator: " + ").replacingOccurrences(of: "+ −", with: "− ")
        return RollResult(expression: expression, total: total, breakdown: breakdown, rolls: rolls)
    }

    /// Convenience using the system RNG.
    static func roll(_ expression: String) -> RollResult? {
        var rng = SystemRandomNumberGenerator()
        return roll(expression, using: &rng)
    }

    /// Roll a single d20 with advantage/disadvantage.
    static func d20(advantage: Bool, disadvantage: Bool, modifier: Int = 0) -> RollResult {
        var rng = SystemRandomNumberGenerator()
        let a = Int.random(in: 1...20, using: &rng)
        let b = Int.random(in: 1...20, using: &rng)
        let pick: Int
        let label: String
        if advantage && !disadvantage { pick = max(a, b); label = "adv [\(a), \(b)]" }
        else if disadvantage && !advantage { pick = min(a, b); label = "dis [\(a), \(b)]" }
        else { pick = a; label = "[\(a)]" }
        let total = pick + modifier
        let modStr = modifier == 0 ? "" : (modifier > 0 ? " + \(modifier)" : " − \(-modifier)")
        return RollResult(expression: "d20\(modStr)", total: total,
                          breakdown: "d20 \(label)\(modStr) = \(total)", rolls: [pick])
    }
}
