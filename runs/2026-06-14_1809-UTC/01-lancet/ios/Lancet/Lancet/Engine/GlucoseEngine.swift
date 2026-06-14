import Foundation

// MARK: - Result value types (Identifiable for Swift Charts)

/// A reading projected for time-series charts.
struct GlucosePoint: Identifiable {
    let id: UUID
    let date: Date
    let mgdl: Double
    let band: GlucoseBand
}

/// Average glucose grouped by reading context.
struct ContextAverage: Identifiable {
    let id = UUID()
    let context: ReadingContext
    let averageMgdl: Double
    let count: Int
}

/// Average glucose grouped by hour of day (0...23).
struct HourlyAverage: Identifiable {
    let id = UUID()
    let hour: Int
    let averageMgdl: Double
    let count: Int

    var label: String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 1..<12: return "\(hour)a"
        default: return "\(hour - 12)p"
        }
    }
}

/// One slice of the time-in-range breakdown.
struct RangeSlice: Identifiable {
    let id = UUID()
    let band: GlucoseBand
    let pct: Double          // 0...1
    var label: String { band.rawValue }
}

/// Aggregated, ready-to-render statistics computed from readings.
struct GlucoseSnapshot {
    var count: Int = 0
    var averageMgdl: Double = 0
    var estimatedA1C: Double = 0       // %
    var gmi: Double = 0                // %
    var timeInRange: Double = 0        // fraction 0...1
    var pctLow: Double = 0             // fraction 0...1
    var pctHigh: Double = 0            // fraction 0...1 (elevated + high combined)
    var variabilityCV: Double = 0      // %
    var hypoCount: Int = 0
    var hyperCount: Int = 0
    var readingsPerDay: Double = 0
    var lastReadingMgdl: Double?
    var lastReadingDate: Date?
    var byContextAverage: [ContextAverage] = []
    var hourlyAverages: [HourlyAverage] = []
    var rangeSlices: [RangeSlice] = []
    var points: [GlucosePoint] = []

    static let empty = GlucoseSnapshot()
}

/// Pure glucose analytics. No SwiftUI / SwiftData imports — operates on fetched arrays.
/// Every division and array access is guarded; empty input returns zeros gracefully.
enum GlucoseEngine {

    /// mg/dL → mmol/L conversion divisor.
    static let mmolDivisor: Double = 18.0182

    static func mmol(from mgdl: Double) -> Double { mgdl / mmolDivisor }

    // MARK: Scalar metrics

    static func averageMgdl(_ readings: [Reading]) -> Double {
        guard !readings.isEmpty else { return 0 }
        let total = readings.reduce(0.0) { $0 + $1.valueMgdl }
        return total / Double(readings.count)
    }

    /// Estimated A1C (%) from average glucose: (avg + 46.7) / 28.7.
    static func estimatedA1C(avgMgdl: Double) -> Double {
        (avgMgdl + 46.7) / 28.7
    }

    /// Glucose Management Indicator (%): 3.31 + 0.02392 * avg.
    static func gmi(avgMgdl: Double) -> Double {
        3.31 + 0.02392 * avgMgdl
    }

    /// Fraction of readings within [low, high].
    static func timeInRange(_ readings: [Reading], low: Double, high: Double) -> Double {
        guard !readings.isEmpty else { return 0 }
        let lo = min(low, high)
        let hi = max(low, high)
        let inRange = readings.filter { $0.valueMgdl >= lo && $0.valueMgdl <= hi }.count
        return Double(inRange) / Double(readings.count)
    }

    static func pctLow(_ readings: [Reading], low: Double) -> Double {
        guard !readings.isEmpty else { return 0 }
        let n = readings.filter { $0.valueMgdl < low }.count
        return Double(n) / Double(readings.count)
    }

    static func pctHigh(_ readings: [Reading], high: Double) -> Double {
        guard !readings.isEmpty else { return 0 }
        let n = readings.filter { $0.valueMgdl > high }.count
        return Double(n) / Double(readings.count)
    }

    /// Coefficient of variation (%) = std / mean * 100. Sample std (n-1) when possible.
    static func variabilityCV(_ readings: [Reading]) -> Double {
        guard readings.count > 1 else { return 0 }
        let values = readings.map { $0.valueMgdl }
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean != 0 else { return 0 }
        let sumSq = values.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) }
        let variance = sumSq / Double(values.count - 1)
        let std = variance.squareRoot()
        return std / mean * 100
    }

    static func readingsPerDay(_ readings: [Reading]) -> Double {
        guard !readings.isEmpty else { return 0 }
        let dates = readings.map { $0.date }
        guard let earliest = dates.min(), let latest = dates.max() else { return 0 }
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: earliest)
        let endDay = cal.startOfDay(for: latest)
        let days = (cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0) + 1
        let span = max(days, 1)
        return Double(readings.count) / Double(span)
    }

    /// Average glucose per context, for contexts that have at least one reading.
    static func byContextAverage(_ readings: [Reading]) -> [ContextAverage] {
        ReadingContext.allCases.compactMap { ctx in
            let matching = readings.filter { $0.context == ctx }
            guard !matching.isEmpty else { return nil }
            let avg = matching.reduce(0.0) { $0 + $1.valueMgdl } / Double(matching.count)
            return ContextAverage(context: ctx, averageMgdl: avg, count: matching.count)
        }
    }

    /// Most recent reading by date.
    static func lastReading(_ readings: [Reading]) -> Reading? {
        readings.max { $0.date < $1.date }
    }

    // MARK: Full snapshot

    static func compute(readings: [Reading], low: Double, high: Double) -> GlucoseSnapshot {
        var snap = GlucoseSnapshot()
        let lo = min(low, high)
        let hi = max(low, high)
        snap.count = readings.count
        guard !readings.isEmpty else { return snap }

        let avg = averageMgdl(readings)
        snap.averageMgdl = avg
        snap.estimatedA1C = estimatedA1C(avgMgdl: avg)
        snap.gmi = gmi(avgMgdl: avg)
        snap.timeInRange = timeInRange(readings, low: lo, high: hi)
        snap.pctLow = pctLow(readings, low: lo)
        snap.pctHigh = pctHigh(readings, high: hi)
        snap.variabilityCV = variabilityCV(readings)
        snap.hypoCount = readings.filter { $0.valueMgdl < lo }.count
        snap.hyperCount = readings.filter { $0.valueMgdl > hi }.count
        snap.readingsPerDay = readingsPerDay(readings)

        if let last = lastReading(readings) {
            snap.lastReadingMgdl = last.valueMgdl
            snap.lastReadingDate = last.date
        }

        snap.byContextAverage = byContextAverage(readings)
        snap.hourlyAverages = hourlySeries(readings)
        snap.rangeSlices = rangeBreakdown(readings, low: lo, high: hi)
        snap.points = readings
            .sorted { $0.date < $1.date }
            .map { GlucosePoint(id: $0.id,
                                date: $0.date,
                                mgdl: $0.valueMgdl,
                                band: GlucoseBand.classify(mgdl: $0.valueMgdl, low: lo, high: hi)) }

        return snap
    }

    // MARK: Helpers

    /// Low / in-range / elevated / high fractions summing to 1 (guarded).
    private static func rangeBreakdown(_ readings: [Reading], low: Double, high: Double) -> [RangeSlice] {
        guard !readings.isEmpty else { return [] }
        let total = Double(readings.count)
        var counts: [GlucoseBand: Int] = [:]
        for r in readings {
            let band = GlucoseBand.classify(mgdl: r.valueMgdl, low: low, high: high)
            counts[band, default: 0] += 1
        }
        // Stable display order: low, in range, elevated, high.
        let order: [GlucoseBand] = [.low, .inRange, .elevated, .high]
        return order.compactMap { band in
            let c = counts[band] ?? 0
            guard c > 0 else { return nil }
            return RangeSlice(band: band, pct: Double(c) / total)
        }
    }

    /// Average glucose by hour of day, only for hours that have readings.
    private static func hourlySeries(_ readings: [Reading]) -> [HourlyAverage] {
        let cal = Calendar.current
        var sums: [Int: Double] = [:]
        var counts: [Int: Int] = [:]
        for r in readings {
            let hour = cal.component(.hour, from: r.date)
            sums[hour, default: 0] += r.valueMgdl
            counts[hour, default: 0] += 1
        }
        return (0..<24).compactMap { hour in
            guard let c = counts[hour], c > 0 else { return nil }
            let avg = (sums[hour] ?? 0) / Double(c)
            return HourlyAverage(hour: hour, averageMgdl: avg, count: c)
        }
    }
}
