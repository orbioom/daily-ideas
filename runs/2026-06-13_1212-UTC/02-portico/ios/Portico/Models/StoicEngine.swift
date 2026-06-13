import Foundation

/// Pure, deterministic helpers for the daily quote and virtue. Everything here
/// is total: every index is guarded, so it can never crash or divide by zero.
enum StoicEngine {

    /// Stable "yyyy-MM-dd" key for a date in the current calendar.
    static func dayKey(_ date: Date) -> String {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2000, m = c.month ?? 1, d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// FNV-1a 32-bit hash over a string — small, fast, deterministic.
    static func fnv1a(_ string: String) -> UInt32 {
        var hash: UInt32 = 0x811c9dc5
        for byte in string.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 0x0100_0193
        }
        return hash
    }

    /// The quote of the day — stable for a given calendar day. Returns nil only
    /// if the library is empty (it never is), so callers can fall back safely.
    static func quoteOfDay(for date: Date, library: [StoicQuote] = QuoteLibrary.all) -> StoicQuote? {
        guard !library.isEmpty else { return nil }
        let h = fnv1a(dayKey(date))
        let idx = Int(h % UInt32(library.count))
        return library.indices.contains(idx) ? library[idx] : library.first
    }

    /// The virtue of the day, rotating the four cardinal virtues by day-of-year.
    static func virtueOfDay(for date: Date) -> Virtue {
        let all = Virtue.allCases
        guard !all.isEmpty else { return .wisdom }
        let doy = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let idx = (doy - 1) % all.count
        return all.indices.contains(idx) ? all[idx] : .wisdom
    }

    /// The free daily quotes a non-Pro user can browse: the day's quote plus a
    /// small deterministic rotation. Pro unlocks the full library.
    static func freeDailySet(for date: Date, count: Int = 6,
                             library: [StoicQuote] = QuoteLibrary.all) -> [StoicQuote] {
        guard !library.isEmpty else { return [] }
        let n = min(max(1, count), library.count)
        let start = Int(fnv1a(dayKey(date)) % UInt32(library.count))
        var result: [StoicQuote] = []
        var i = 0
        while result.count < n && i < library.count {
            let idx = (start + i) % library.count
            result.append(library[idx])
            i += 1
        }
        return result
    }
}
