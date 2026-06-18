import Foundation

/// A curated puzzle seed: a center letter plus six outer letters (all seven distinct).
struct PangramSeed: Hashable {
    let center: String
    let outer: [String]

    /// All seven letters as a set (lowercased single characters).
    var letterSet: Set<Character> {
        var set = Set<Character>()
        if let c = center.first { set.insert(c) }
        for o in outer { if let ch = o.first { set.insert(ch) } }
        return set
    }
}
