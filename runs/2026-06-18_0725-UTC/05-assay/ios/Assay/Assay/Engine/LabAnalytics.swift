import Foundation

/// A grouped panel (all results from one draw), sorted by date desc.
struct Panel: Identifiable {
    let id: String          // panelId
    let drawDate: Date
    let labName: String
    let results: [LabResult]
}

/// Stateless analytics layer that turns a flat `[LabResult]` into the grouped
/// and derived structures the UI needs. All access is guarded.
enum LabAnalytics {

    /// Group results into panels (by panelId), newest first.
    static func panels(from results: [LabResult]) -> [Panel] {
        let grouped = Dictionary(grouping: results) { $0.panelId }
        let panels: [Panel] = grouped.compactMap { (pid, rows) in
            guard let first = rows.first else { return nil }
            let sorted = rows.sorted { lhs, rhs in
                (lhs.marker?.name ?? lhs.markerId) < (rhs.marker?.name ?? rhs.markerId)
            }
            return Panel(id: pid, drawDate: first.drawDate, labName: first.labName, results: sorted)
        }
        return panels.sorted { $0.drawDate > $1.drawDate }
    }

    /// Most recent panel, if any.
    static func latestPanel(from results: [LabResult]) -> Panel? {
        panels(from: results).first
    }

    /// All history for one marker, oldest→newest, as canonical samples.
    static func samples(for markerId: String, results: [LabResult]) -> [TrendSample] {
        guard let marker = BiomarkerCatalog.marker(markerId) else { return [] }
        return results
            .filter { $0.markerId == markerId }
            .map { r -> TrendSample in
                let canon = UnitConverter.toCanonical(value: r.value, rawUnit: r.unitRaw, marker: marker)
                return TrendSample(date: r.drawDate, canonicalValue: canon)
            }
            .sorted { $0.date < $1.date }
    }

    /// Latest result per marker → snapshots (latest assessment).
    static func latestSnapshots(from results: [LabResult], sex: BiologicalSex) -> [MarkerSnapshot] {
        var latestByMarker: [String: LabResult] = [:]
        for r in results {
            if let existing = latestByMarker[r.markerId] {
                if r.drawDate > existing.drawDate { latestByMarker[r.markerId] = r }
            } else {
                latestByMarker[r.markerId] = r
            }
        }
        var snaps: [MarkerSnapshot] = []
        for (_, r) in latestByMarker {
            guard let marker = r.marker else { continue }
            let a = RangeEngine.assess(marker: marker, rawValue: r.value, rawUnit: r.unitRaw, sex: sex)
            snaps.append(MarkerSnapshot(marker: marker, assessment: a, drawDate: r.drawDate))
        }
        return snaps.sorted { $0.marker.name < $1.marker.name }
    }

    /// Distinct marker ids that the user has logged at least once.
    static func trackedMarkerIds(from results: [LabResult]) -> Set<String> {
        Set(results.map { $0.markerId })
    }

    /// Optimal midpoint (canonical) for a marker for trend direction, if defined.
    static func optimalMid(for marker: Biomarker, sex: BiologicalSex) -> Double? {
        let opt = marker.optimal.range(for: sex)
        switch (opt.low, opt.high) {
        case let (lo?, hi?): return (lo + hi) / 2
        case let (lo?, nil): return lo
        case let (nil, hi?): return hi
        case (nil, nil): return nil
        }
    }

    /// In-range fraction across panels over time (for the insights line chart).
    static func inRangeOverTime(from results: [LabResult], sex: BiologicalSex) -> [(date: Date, fraction: Double)] {
        let ps = panels(from: results).sorted { $0.drawDate < $1.drawDate }
        return ps.compactMap { panel in
            guard let s = StatsEngine.summarize(panelResults: panel.results, sex: sex) else { return nil }
            let frac = StatsEngine.inRangeFraction(optimal: s.optimalCount, inRange: s.inRangeCount, outOfRange: s.outOfRangeCount)
            return (panel.drawDate, frac)
        }
    }
}
