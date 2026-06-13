import Foundation

/// Maps a calendar day to a deterministic puzzle from the bank, using a
/// SplitMix64 hash over the "yyyy-MM-dd" key so the same day always yields the
/// same puzzle on every device, fully offline.
enum DailyEngine {
    /// The canonical day key, e.g. "2026-06-13", in the user's calendar.
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        var cal = calendar
        cal.timeZone = .current
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2000, m = c.month ?? 1, d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// SplitMix64 — a tiny, well-mixed integer hash.
    private static func mix(_ seed: UInt64) -> UInt64 {
        var z = seed &+ 0x9E3779B97F4A7C15
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A stable 64-bit hash of a string via FNV-1a, then SplitMix64.
    static func hash(_ key: String) -> UInt64 {
        var h: UInt64 = 0xCBF29CE484222325
        for byte in key.utf8 {
            h ^= UInt64(byte)
            h = h &* 0x100000001B3
        }
        return mix(h)
    }

    /// The puzzle index for a given day, in 0..<count.
    static func puzzleIndex(for date: Date, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(hash(dayKey(for: date)) % UInt64(count))
    }
}
