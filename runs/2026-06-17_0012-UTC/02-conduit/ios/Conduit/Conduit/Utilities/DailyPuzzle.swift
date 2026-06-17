import Foundation

/// Deterministic daily-puzzle selection and day-key helpers.
enum DailyPuzzle {

    /// Stable "yyyy-MM-dd" key for a date in the user's current calendar.
    static func dayKey(for date: Date = .now) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// A deterministic integer seed derived from the day key.
    static func seed(for date: Date = .now) -> Int {
        let key = dayKey(for: date)
        var hash = 5381
        for byte in key.utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)   // djb2, overflow-safe with &
        }
        return abs(hash)
    }

    /// The puzzle chosen for a given date. Daily draws from the FREE packs so it is
    /// always playable; Pro unlocks the archive of past days, not today's puzzle.
    static func puzzle(for date: Date = .now) -> Puzzle? {
        let pool = PuzzleBank.all.filter { !$0.packId.requiresPro }
        guard !pool.isEmpty else { return PuzzleBank.all.first }
        let idx = seed(for: date) % pool.count
        return pool[safe: idx]
    }

    /// Format seconds as m:ss.
    static func formatTime(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
