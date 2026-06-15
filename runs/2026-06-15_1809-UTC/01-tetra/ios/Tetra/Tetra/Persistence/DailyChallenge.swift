import Foundation

/// Derives a stable per-day seed so everyone playing the daily challenge on the
/// same calendar date gets the same board. Pure & testable.
enum DailyChallenge {
    /// A reproducible integer seed for the given date's calendar day.
    static func seed(for date: Date, calendar: Calendar = .current) -> Int {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        // Mix the components through SplitMix64 for a well-distributed seed.
        let base = UInt64(y) &* 10_000 &+ UInt64(m) &* 100 &+ UInt64(d)
        var rng = SplitMix64(seed: base &+ 0x1234_5678)
        return Int(bitPattern: UInt(truncatingIfNeeded: rng.next()))
    }

    /// A short label like "Jun 15" for the day's challenge.
    static func label(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    /// True if a daily record already exists for `date`'s calendar day.
    static func alreadyPlayed(records: [GameRecord], on date: Date, calendar: Calendar = .current) -> Bool {
        records.contains { $0.mode == .daily && calendar.isDate($0.date, inSameDayAs: date) }
    }
}
