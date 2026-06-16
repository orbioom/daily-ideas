import Foundation

/// A puzzle is uniquely identified by (pack, index, difficulty). Its seed is derived
/// deterministically so the same puzzle always generates the same board.
struct Puzzle: Identifiable, Hashable {
    let packID: String
    let index: Int
    let difficulty: Difficulty

    var id: String { key }

    /// Stable storage key: "pack|index|difficulty".
    var key: String { "\(packID)|\(index)|\(difficulty.rawValue)" }

    /// Human display title, e.g. "Animals 3".
    func title(packName: String) -> String {
        "\(packName) \(index + 1)"
    }

    /// Deterministic seed from the key. FNV-1a hash → stable across launches and devices.
    var seed: UInt64 {
        Puzzle.fnv1a(key)
    }

    /// Whether this puzzle is locked for free users (past the per-pack free cap or a Pro pack).
    func isLocked(isPro: Bool, packIsPro: Bool) -> Bool {
        if isPro { return false }
        if packIsPro { return true }
        return index >= FreeTier.puzzlesPerPackPerDifficulty
    }

    static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}

/// Daily puzzle identity: deterministic from the calendar day.
enum DailyPuzzle {
    /// The daily always uses the Medium difficulty and a rotating free pack.
    static let difficulty: Difficulty = .medium

    static func seed(for dateKey: String) -> UInt64 {
        Puzzle.fnv1a("daily|" + dateKey)
    }

    /// Rotates deterministically through the free packs by day.
    static func pack(for dateKey: String) -> WordPack {
        let packs = WordPackLibrary.freePacks
        guard !packs.isEmpty else {
            // Unreachable: the library always contains free packs.
            return WordPackLibrary.all.first ?? WordPack(
                id: "fallback", name: "Daily", symbol: "calendar",
                tint: 0xE0654E, isPro: false, words: ["SEEK", "DAILY", "WORD", "FIND"]
            )
        }
        let idx = Int(seed(for: dateKey) % UInt64(packs.count))
        return packs[idx]
    }
}
