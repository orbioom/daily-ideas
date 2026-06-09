import Foundation

/// Pure analytics over `[VitalEntry]`. Every aggregate guards against empty
/// inputs and divide-by-zero. No SwiftUI, no SwiftData mutation.
enum VitalsEngine {

    // MARK: - Filtering

    static func entries(_ all: [VitalEntry], kind: VitalKind) -> [VitalEntry] {
        all.filter { $0.kind == kind }.sorted { $0.date > $1.date }
    }

    static func latest(_ all: [VitalEntry], kind: VitalKind) -> VitalEntry? {
        entries(all, kind: kind).first
    }

    static func count(_ all: [VitalEntry], kind: VitalKind) -> Int {
        entries(all, kind: kind).count
    }

    static func within(_ entries: [VitalEntry], days: Int, now: Date = .now,
                        calendar: Calendar = .current) -> [VitalEntry] {
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: now) else { return entries }
        return entries.filter { $0.date >= cutoff }
    }

    // MARK: - Generic value averages (weight / glucose / spo2 / pulse-only)

    static func averageValue(_ entries: [VitalEntry]) -> Double? {
        guard !entries.isEmpty else { return nil }
        let total = entries.reduce(0.0) { $0 + $1.value }
        return total / Double(entries.count)
    }

    static func minMaxValue(_ entries: [VitalEntry]) -> (min: Double, max: Double)? {
        let values = entries.map(\.value)
        guard let lo = values.min(), let hi = values.max() else { return nil }
        return (lo, hi)
    }

    static func minMaxSystolic(_ entries: [VitalEntry]) -> (min: Int, max: Int)? {
        let values = entries.map(\.systolic)
        guard let lo = values.min(), let hi = values.max() else { return nil }
        return (lo, hi)
    }

    // MARK: - Blood-pressure averages

    struct BPAverage {
        var systolic: Int
        var diastolic: Int
        var pulse: Int          // 0 when no pulse readings were present
        var count: Int
        var category: BPCategory {
            BPClassifier.classify(systolic: systolic, diastolic: diastolic)
        }
    }

    static func bpAverage(_ entries: [VitalEntry]) -> BPAverage? {
        guard !entries.isEmpty else { return nil }
        let sys = entries.reduce(0) { $0 + $1.systolic }
        let dia = entries.reduce(0) { $0 + $1.diastolic }
        let pulseReadings = entries.filter { $0.pulse > 0 }
        let pulseAvg = pulseReadings.isEmpty
            ? 0
            : pulseReadings.reduce(0) { $0 + $1.pulse } / pulseReadings.count
        return BPAverage(
            systolic: Int((Double(sys) / Double(entries.count)).rounded()),
            diastolic: Int((Double(dia) / Double(entries.count)).rounded()),
            pulse: pulseAvg,
            count: entries.count
        )
    }

    /// Morning vs evening BP averages over the given entries.
    static func morningEveningBP(_ entries: [VitalEntry]) -> (morning: BPAverage?, evening: BPAverage?) {
        let morning = bpAverage(entries.filter { $0.tag == .morning })
        let evening = bpAverage(entries.filter { $0.tag == .evening })
        return (morning, evening)
    }

    // MARK: - In-target percentage

    /// Fraction (0…1) of BP readings at or below the target systolic AND diastolic.
    static func bpInTargetFraction(_ entries: [VitalEntry],
                                   targetSystolic: Int,
                                   targetDiastolic: Int) -> Double? {
        guard !entries.isEmpty else { return nil }
        let hits = entries.filter { $0.systolic <= targetSystolic && $0.diastolic <= targetDiastolic }
        return Double(hits.count) / Double(entries.count)
    }

    // MARK: - Category distribution

    static func categoryDistribution(_ entries: [VitalEntry]) -> [(category: BPCategory, count: Int)] {
        var counts: [BPCategory: Int] = [:]
        for e in entries { counts[e.category, default: 0] += 1 }
        return BPCategory.allCases.map { ($0, counts[$0] ?? 0) }
    }

    // MARK: - Trend (delta vs the prior equal-length window)

    enum TrendDirection { case up, down, flat }

    struct Trend {
        var delta: Double           // current period mean − prior period mean
        var direction: TrendDirection
    }

    /// Trend of a generic value metric across two adjacent windows of `days`.
    static func valueTrend(_ entries: [VitalEntry], days: Int, now: Date = .now,
                           calendar: Calendar = .current) -> Trend? {
        guard let midpoint = calendar.date(byAdding: .day, value: -days, to: now),
              let start = calendar.date(byAdding: .day, value: -days, to: midpoint) else { return nil }
        let current = entries.filter { $0.date >= midpoint && $0.date <= now }
        let prior = entries.filter { $0.date >= start && $0.date < midpoint }
        guard let curAvg = averageValue(current), let priAvg = averageValue(prior) else { return nil }
        return trend(from: priAvg, to: curAvg)
    }

    /// Trend of systolic across two adjacent windows of `days`.
    static func systolicTrend(_ entries: [VitalEntry], days: Int, now: Date = .now,
                              calendar: Calendar = .current) -> Trend? {
        guard let midpoint = calendar.date(byAdding: .day, value: -days, to: now),
              let start = calendar.date(byAdding: .day, value: -days, to: midpoint) else { return nil }
        let current = entries.filter { $0.date >= midpoint && $0.date <= now }
        let prior = entries.filter { $0.date >= start && $0.date < midpoint }
        guard let cur = bpAverage(current), let pri = bpAverage(prior) else { return nil }
        return trend(from: Double(pri.systolic), to: Double(cur.systolic))
    }

    private static func trend(from prior: Double, to current: Double) -> Trend {
        let delta = current - prior
        let direction: TrendDirection
        if abs(delta) < 0.5 { direction = .flat }
        else if delta > 0 { direction = .up }
        else { direction = .down }
        return Trend(delta: delta, direction: direction)
    }

    // MARK: - Chart series

    struct BPPoint: Identifiable {
        let id: UUID = UUID()
        let date: Date
        let systolic: Int
        let diastolic: Int
    }

    struct ValuePoint: Identifiable {
        let id: UUID = UUID()
        let date: Date
        let value: Double
    }

    static func bpSeries(_ entries: [VitalEntry]) -> [BPPoint] {
        entries.sorted { $0.date < $1.date }
            .map { BPPoint(date: $0.date, systolic: $0.systolic, diastolic: $0.diastolic) }
    }

    static func valueSeries(_ entries: [VitalEntry]) -> [ValuePoint] {
        entries.sorted { $0.date < $1.date }
            .map { ValuePoint(date: $0.date, value: $0.value) }
    }
}
