import Foundation
import SwiftData

/// Seeds a rich starter library — ~12 trackers across every kind — plus ~60 days of *correlated*
/// synthetic log entries so the Insights screen has real, non-trivial findings on first launch and
/// in previews. The synthetic model bakes in honest relationships (caffeine → headache, sleep →
/// mood, water → headache↓, stress → anxiety, screen time → brain fog) so the engine has something
/// true to discover. Deterministic via SplitMix64.
enum SeedData {

    /// A blueprint for a starter tracker plus how its synthetic series is generated.
    private struct Blueprint {
        let name: String
        let kind: TrackerKind
        let scale: ScaleType
        let unit: String?
        let colorHex: String
        let symbol: String
    }

    private static let blueprints: [Blueprint] = [
        Blueprint(name: "Mood", kind: .mood, scale: .severity, unit: nil, colorHex: "7C5CFF", symbol: "face.smiling"),
        Blueprint(name: "Energy", kind: .mood, scale: .severity, unit: nil, colorHex: "F0A93B", symbol: "bolt.fill"),
        Blueprint(name: "Headache", kind: .symptom, scale: .severity, unit: nil, colorHex: "E0584F", symbol: "bolt.heart"),
        Blueprint(name: "Anxiety", kind: .symptom, scale: .severity, unit: nil, colorHex: "5BB5C9", symbol: "wind"),
        Blueprint(name: "Brain fog", kind: .symptom, scale: .severity, unit: nil, colorHex: "8A7CC2", symbol: "cloud.fog"),
        Blueprint(name: "Sleep", kind: .measurement, scale: .numeric, unit: "hrs", colorHex: "4C6EF5", symbol: "bed.double"),
        Blueprint(name: "Caffeine", kind: .factor, scale: .count, unit: "cups", colorHex: "9C6B3C", symbol: "cup.and.saucer"),
        Blueprint(name: "Water", kind: .factor, scale: .count, unit: "glasses", colorHex: "37A2B8", symbol: "drop"),
        Blueprint(name: "Steps", kind: .measurement, scale: .numeric, unit: "k", colorHex: "47B27A", symbol: "figure.walk"),
        Blueprint(name: "Stress", kind: .factor, scale: .severity, unit: nil, colorHex: "D08A2E", symbol: "exclamationmark.triangle"),
        Blueprint(name: "Screen time", kind: .factor, scale: .numeric, unit: "hrs", colorHex: "B0588F", symbol: "iphone"),
        Blueprint(name: "Ibuprofen", kind: .medication, scale: .yesNo, unit: nil, colorHex: "C7506A", symbol: "pills")
    ]

    /// Names a freshly-onboarding user is offered as "starter" picks.
    static let starterNames = ["Mood", "Energy", "Headache", "Sleep", "Caffeine", "Water", "Stress"]

    static let seedDayCount = 60

    /// Seed trackers + entries once. Gated by the caller's `didSeed` flag.
    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool, activeNames: [String]? = nil) {
        guard !didSeed else { return }
        // Don't double-seed if a previous launch already created trackers.
        let existing = (try? context.fetchCount(FetchDescriptor<Tracker>())) ?? 0
        if existing == 0 {
            seedAll(context: context, activeNames: activeNames)
        }
        didSeed = true
    }

    /// Insert all blueprints and their synthetic histories. `activeNames`, when provided, marks
    /// only those trackers active (the rest are seeded but hidden) so onboarding choices stick.
    static func seedAll(context: ModelContext, activeNames: [String]? = nil) {
        var rng = SplitMix64(seed: 0x1C5EED_BEEF)
        let days = DayMath.recentDays(seedDayCount)

        // 1) Create trackers.
        var trackers: [String: Tracker] = [:]
        for (i, bp) in blueprints.enumerated() {
            let active = activeNames.map { $0.contains(bp.name) } ?? true
            let t = Tracker(name: bp.name,
                            kind: bp.kind,
                            scaleType: bp.scale,
                            unit: bp.unit,
                            colorHex: bp.colorHex,
                            symbolName: bp.symbol,
                            isActive: active,
                            sortOrder: i)
            context.insert(t)
            trackers[bp.name] = t
        }

        // 2) Generate driver series (the independent factors) day by day.
        var series: [String: [Double]] = [:]
        for bp in blueprints { series[bp.name] = [] }

        for index in 0..<days.count {
            // Smooth weekly rhythms make the synthetic data feel human.
            let wk = Double(index) * (2.0 * .pi / 7.0)

            let stress = clamp(2.0 + 1.4 * sin(wk) + rng.gaussian() * 0.7, 0, 4)
            let caffeine = clamp((1.0 + stress * 0.8 + rng.gaussian() * 1.1).rounded(), 0, 6)
            let screen = clamp(3.0 + stress * 0.6 + rng.gaussian() * 1.0, 0.5, 10)
            let water = clamp((6.0 - stress * 0.5 + rng.gaussian() * 1.4).rounded(), 0, 12)
            let steps = clamp(7.0 - stress * 0.4 + rng.gaussian() * 2.0, 1, 18)
            let sleep = clamp(7.5 - caffeine * 0.35 - stress * 0.2 + rng.gaussian() * 0.8, 3.5, 10)

            // Outcomes depend on the drivers (with a touch of carry-over and noise).
            let prevCaffeine = series["Caffeine"]?.last ?? caffeine
            let headache = clamp(0.6 + caffeine * 0.45 + prevCaffeine * 0.2 - water * 0.12
                                 + rng.gaussian() * 0.6, 0, 4)
            let mood = clamp(2.2 + (sleep - 7.0) * 0.5 - stress * 0.4 + steps * 0.05
                             + rng.gaussian() * 0.5, 0, 4)
            let energy = clamp(2.0 + (sleep - 7.0) * 0.45 + steps * 0.06 - caffeine * 0.05
                               + rng.gaussian() * 0.5, 0, 4)
            let anxiety = clamp(0.8 + stress * 0.7 - sleep * 0.1 + rng.gaussian() * 0.5, 0, 4)
            let fog = clamp(0.7 + screen * 0.18 + (7.0 - sleep) * 0.25 + rng.gaussian() * 0.5, 0, 4)
            // Ibuprofen tends to be taken on bad-headache days.
            let ibuprofen: Double = (headache >= 2.2 && rng.unit() < 0.7) ? 1 : 0

            append(&series, "Stress", round1(stress))
            append(&series, "Caffeine", caffeine)
            append(&series, "Screen time", round1(screen))
            append(&series, "Water", water)
            append(&series, "Steps", round1(steps))
            append(&series, "Sleep", round1(sleep))
            append(&series, "Headache", headache.rounded())
            append(&series, "Mood", mood.rounded())
            append(&series, "Energy", energy.rounded())
            append(&series, "Anxiety", anxiety.rounded())
            append(&series, "Brain fog", fog.rounded())
            append(&series, "Ibuprofen", ibuprofen)
        }

        // 3) Materialise log entries. Occasionally skip a day to look realistic (~12% gaps).
        for bp in blueprints {
            guard let tracker = trackers[bp.name], let values = series[bp.name] else { continue }
            for (i, day) in days.enumerated() {
                guard i < values.count else { break }
                if rng.unit() < 0.12 { continue }   // a natural missed log
                let entry = LogEntry(date: day, value: values[i], tracker: tracker)
                context.insert(entry)
            }
        }

        try? context.save()
    }

    /// Wipe every entry, keep trackers, then regenerate a fresh synthetic history.
    static func reseedHistory(context: ModelContext) {
        if let entries = try? context.fetch(FetchDescriptor<LogEntry>()) {
            for e in entries { context.delete(e) }
        }
        try? context.save()
        // Re-fetch current trackers and rebuild from blueprints where names match.
        regenerateEntries(context: context)
    }

    /// Rebuild synthetic entries for the existing trackers (used by "reload sample data").
    private static func regenerateEntries(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Tracker>())) ?? []
        guard !existing.isEmpty else {
            seedAll(context: context)
            return
        }
        // Easiest correct approach: clear everything and seed fresh, preserving active flags.
        let activeNames = existing.filter(\.isActive).map(\.name)
        for t in existing { context.delete(t) }
        try? context.save()
        seedAll(context: context, activeNames: activeNames.isEmpty ? nil : activeNames)
    }

    /// Delete all trackers and entries (cascade removes entries).
    static func eraseAll(context: ModelContext) {
        if let trackers = try? context.fetch(FetchDescriptor<Tracker>()) {
            for t in trackers { context.delete(t) }
        }
        if let entries = try? context.fetch(FetchDescriptor<LogEntry>()) {
            for e in entries { context.delete(e) }
        }
        try? context.save()
    }

    // MARK: helpers

    private static func append(_ dict: inout [String: [Double]], _ key: String, _ value: Double) {
        dict[key, default: []].append(value)
    }

    private static func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(v, lo), hi)
    }

    private static func round1(_ v: Double) -> Double {
        (v * 10).rounded() / 10
    }
}
