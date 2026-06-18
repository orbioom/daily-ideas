import Foundation
import SwiftData

/// Seeds realistic, trending sample data on first launch so charts, trends
/// and insights are compelling immediately. Guarded to run once.
enum SeedData {

    private static let seededKey = "assay.didSeed.v1"

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: seededKey) { return }

        // Extra guard: don't double-seed if results already exist.
        let existing = (try? context.fetch(FetchDescriptor<LabResult>())) ?? []
        if !existing.isEmpty {
            defaults.set(true, forKey: seededKey)
            return
        }

        for panel in makePanels() {
            for result in panel {
                context.insert(result)
            }
        }
        try? context.save()
        defaults.set(true, forKey: seededKey)
    }

    /// 5 panels spanning ~18 months, each ~15 markers, values that TREND.
    private static func makePanels() -> [[LabResult]] {
        let cal = Calendar.current
        let now = Date()
        // Draw dates: ~18, 14, 9, 4 months ago, and ~2 weeks ago.
        let offsets = [-548, -425, -274, -122, -16]
        let labs = ["Quest Diagnostics", "Quest Diagnostics", "Labcorp", "Labcorp", "InsideTracker"]

        var panels: [[LabResult]] = []

        for (i, days) in offsets.enumerated() {
            let date = cal.date(byAdding: .day, value: days, to: now) ?? now
            let pid = "seed-panel-\(i)"
            let lab = labs[safe: i] ?? "Labcorp"
            // t goes 0…1 across the timeline; used to interpolate trends.
            let t = Double(i) / Double(max(offsets.count - 1, 1))
            panels.append(makePanel(date: date, pid: pid, lab: lab, t: t))
        }
        return panels
    }

    /// Build one panel. `t` 0 (oldest) … 1 (newest) drives the trend.
    private static func makePanel(date: Date, pid: String, lab: String, t: Double) -> [LabResult] {
        // Each entry: markerId → value as a function of t (canonical units).
        // Designed so: LDL/ApoB/Trig improve (fall), Vit D rises, A1c steady,
        // hs-CRP falls, HDL rises, ferritin rises slightly, etc.
        let spec: [(String, Double)] = [
            ("ldl",            lerp(148, 86, t)),    // improving
            ("hdl",            lerp(48, 61, t)),     // improving (rises)
            ("triglycerides",  lerp(165, 92, t)),    // improving
            ("apob",           lerp(108, 74, t)),    // improving
            ("total_chol",     lerp(214, 178, t)),   // improving
            ("glucose",        lerp(96, 88, t)),     // slight improve
            ("hba1c",          lerp(5.4, 5.3, t)),   // steady
            ("insulin",        lerp(11, 6, t)),      // improving
            ("hscrp",          lerp(2.6, 0.8, t)),   // improving
            ("homocysteine",   lerp(11.5, 8.2, t)),  // improving
            ("vitd",           lerp(24, 48, t)),     // rising
            ("b12",            lerp(420, 610, t)),   // rising
            ("ferritin",       lerp(58, 92, t)),     // rising into optimal
            ("tsh",            lerp(2.2, 1.8, t)),   // steady-ish
            ("alt",            lerp(34, 21, t)),     // improving
            ("hemoglobin",     lerp(14.2, 14.6, t)), // steady
            ("creatinine",     lerp(0.95, 0.92, t)), // steady
            ("egfr",           lerp(96, 104, t)),    // slight rise
            ("albumin",        lerp(4.2, 4.6, t)),   // rising
            ("testosterone",   lerp(520, 640, t))    // rising (sample profile)
        ]

        // Deterministic, tiny per-draw jitter so lines aren't perfectly smooth.
        var results: [LabResult] = []
        for (idx, item) in spec.enumerated() {
            let (markerId, base) = item
            guard let marker = BiomarkerCatalog.marker(markerId) else { continue }
            let jitter = deterministicJitter(seed: pid.hashValue &+ idx, magnitude: base * 0.02)
            let value = roundForUnit(base + jitter, unit: marker.unit)
            let r = LabResult(
                markerId: markerId,
                value: value,
                unitRaw: marker.unit,
                drawDate: date,
                panelId: pid,
                labName: lab,
                note: ""
            )
            results.append(r)
        }
        return results
    }

    /// Linear interpolation between start (t=0) and end (t=1).
    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        let clamped = Swift.min(1, Swift.max(0, t))
        return a + (b - a) * clamped
    }

    /// Small bounded deterministic jitter (no Foundation RNG needed; stable).
    private static func deterministicJitter(seed: Int, magnitude: Double) -> Double {
        guard magnitude.isFinite, magnitude != 0 else { return 0 }
        // Simple hash → -1…1 fraction.
        let h = UInt64(bitPattern: Int64(seed &* 2_654_435_761))
        let frac = Double(h % 2000) / 1000.0 - 1.0 // -1…1
        return frac * magnitude
    }

    /// Round to a sensible precision based on the unit's typical magnitude.
    private static func roundForUnit(_ v: Double, unit: String) -> Double {
        guard v.isFinite else { return v }
        let absV = abs(v)
        if absV >= 100 { return (v).rounded() }
        if absV >= 10 { return (v * 10).rounded() / 10 }
        return (v * 100).rounded() / 100
    }
}

extension Array {
    /// Safe index access — returns nil instead of crashing on out-of-bounds.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
