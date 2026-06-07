import Foundation

/// A single dart, expressed as a ring + segment value.
struct Dart: Hashable, Identifiable {
    enum Ring: String, Codable { case single, double, treble, outerBull, bull, miss }
    let ring: Ring
    let value: Int   // 1...20 for single/double/treble; 25 for bull rings; 0 for miss

    var id: String { label }

    var score: Int {
        switch ring {
        case .single:    return value
        case .double:    return value * 2
        case .treble:    return value * 3
        case .outerBull: return 25
        case .bull:      return 50
        case .miss:      return 0
        }
    }

    /// Is this dart a valid finishing dart for double-out rules?
    var isFinishing: Bool { ring == .double || ring == .bull }

    var label: String {
        switch ring {
        case .single:    return "S\(value)"
        case .double:    return "D\(value)"
        case .treble:    return "T\(value)"
        case .outerBull: return "25"
        case .bull:      return "Bull"
        case .miss:      return "Miss"
        }
    }

    /// A spoken form for accessibility.
    var spoken: String {
        switch ring {
        case .single:    return "single \(value)"
        case .double:    return "double \(value)"
        case .treble:    return "treble \(value)"
        case .outerBull: return "outer bull, twenty-five"
        case .bull:      return "bullseye, fifty"
        case .miss:      return "miss"
        }
    }

    static func single(_ v: Int) -> Dart { Dart(ring: .single, value: v) }
    static func double(_ v: Int) -> Dart { Dart(ring: .double, value: v) }
    static func treble(_ v: Int) -> Dart { Dart(ring: .treble, value: v) }
    static let outerBull = Dart(ring: .outerBull, value: 25)
    static let bull = Dart(ring: .bull, value: 25)
}

/// Pure, value-type checkout solver. Given a remaining score and a number of
/// darts in hand, it returns a conventional finishing route that ends on a
/// double (or the bull) — the way the math actually works in a 501 leg.
enum CheckoutEngine {

    /// All legal finishing darts (a double 1–20, or the 50 bull).
    static let finishers: [Dart] =
        (1...20).map { Dart.double($0) } + [.bull]

    /// Setup darts ordered by descending "pro preference": heavy trebles first,
    /// then singles that tidy the score, then the 25/bull. Ordering this list is
    /// what makes the first solution the conventional one (T20, T20, Bull for 170).
    static let setupDarts: [Dart] = {
        var darts: [Dart] = []
        // Trebles 20 down to 1 (highest scoring setups first).
        darts += (1...20).reversed().map { Dart.treble($0) }
        // Bull and outer bull as setups.
        darts += [.bull, .outerBull]
        // Singles 20 down to 1.
        darts += (1...20).reversed().map { Dart.single($0) }
        return darts
    }()

    /// Is a finish even possible in `darts` throws for this score?
    static func isCheckoutPossible(_ score: Int, darts: Int = 3) -> Bool {
        bestCheckout(score, darts: darts) != nil
    }

    /// The conventional minimal-dart finish, or nil if it can't be done.
    /// Always ends on a double/bull (double-out).
    static func bestCheckout(_ score: Int, darts maxDarts: Int = 3) -> [Dart]? {
        guard score >= 2, score <= 170, maxDarts >= 1, maxDarts <= 3 else { return nil }
        for n in 1...maxDarts {
            if let path = search(remaining: score, darts: n) {
                return path
            }
        }
        return nil
    }

    /// Up to `limit` distinct valid routes (primary first), for showing alternates.
    static func alternativeCheckouts(_ score: Int, darts maxDarts: Int = 3, limit: Int = 3) -> [[Dart]] {
        guard let primary = bestCheckout(score, darts: maxDarts) else { return [] }
        var results: [[Dart]] = [primary]
        let n = primary.count
        // Vary the first dart to surface a couple of conventional alternates.
        for first in setupDarts where first.score < score {
            if results.count >= limit { break }
            guard n >= 2 else { break }
            if let rest = search(remaining: score - first.score, darts: n - 1) {
                let candidate = [first] + rest
                if !results.contains(candidate) { results.append(candidate) }
            }
        }
        return Array(results.prefix(limit))
    }

    /// Recursive search for a finish of exactly `darts` darts.
    private static func search(remaining: Int, darts: Int) -> [Dart]? {
        if darts == 1 {
            // One dart left → must be a finishing double/bull hitting exactly.
            if remaining == 50 { return [.bull] }
            if remaining % 2 == 0, remaining / 2 >= 1, remaining / 2 <= 20 {
                return [Dart.double(remaining / 2)]
            }
            return nil
        }
        // Choose a setup dart, then solve the rest.
        for first in setupDarts where first.score < remaining {
            // Avoid leaving a remainder that can never finish (odd 1, or > finishable).
            let rest = remaining - first.score
            if rest < 2 { continue }
            if let tail = search(remaining: rest, darts: darts - 1) {
                return [first] + tail
            }
        }
        return nil
    }

    /// A label like "T20 T20 Bull" for a route.
    static func routeLabel(_ route: [Dart]) -> String {
        route.map(\.label).joined(separator: " ")
    }
}
