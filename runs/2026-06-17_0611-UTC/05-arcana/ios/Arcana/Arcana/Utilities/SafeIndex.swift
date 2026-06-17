import Foundation

extension Collection {
    /// Safe subscript: returns nil instead of trapping on an out-of-bounds index.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Date {
    /// The calendar day key (yyyy-MM-dd in the current calendar/timezone) — the basis for the
    /// deterministic daily draw. Two `Date`s on the same local day share a key.
    var dayKey: String {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day], from: self)
        let y = c.year ?? 2000
        let m = c.month ?? 1
        let d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Start of the local day — used to compare and store daily draws.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
