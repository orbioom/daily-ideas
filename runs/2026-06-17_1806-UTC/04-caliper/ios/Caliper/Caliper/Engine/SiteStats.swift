import Foundation

/// Computed statistics for a single site over a set of entries (canonical units).
struct SiteStats {
    let current: Double?
    let previous: Double?
    let min: Double?
    let max: Double?
    let average: Double?
    let weeklyRate: Double?
    let count: Int

    /// Change from previous entry to current (canonical units).
    var changeSincePrevious: Double? {
        guard let current, let previous else { return nil }
        return current - previous
    }

    /// Total change across the whole window (first -> last).
    let totalChange: Double?

    static let empty = SiteStats(
        current: nil, previous: nil, min: nil, max: nil,
        average: nil, weeklyRate: nil, count: 0, totalChange: nil
    )

    /// `entries` need not be sorted; values are canonical.
    static func compute(entries: [MeasurementEntry]) -> SiteStats {
        guard !entries.isEmpty else { return .empty }
        let sorted = entries.sorted { $0.date < $1.date }
        let values = sorted.map { $0.valueCanonical }
        let current = values.last
        let previous = values.count >= 2 ? values[values.count - 2] : nil
        let minV = values.min()
        let maxV = values.max()
        let avg = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
        let rate = BodyMath.weeklyRate(points: sorted.map { ($0.date, $0.valueCanonical) })
        let total: Double?
        if let first = values.first, let last = values.last {
            total = last - first
        } else {
            total = nil
        }
        return SiteStats(
            current: current,
            previous: previous,
            min: minV,
            max: maxV,
            average: avg,
            weeklyRate: rate,
            count: values.count,
            totalChange: total
        )
    }
}
