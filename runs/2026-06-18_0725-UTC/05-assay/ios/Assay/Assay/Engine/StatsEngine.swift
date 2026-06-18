import Foundation

/// Summary of a single panel (one blood draw).
struct PanelSummary {
    let panelId: String
    let drawDate: Date
    let labName: String
    let resultCount: Int
    let optimalCount: Int
    let inRangeCount: Int     // in standard range but not optimal
    let outOfRangeCount: Int
    /// 0…100 health-ish score (heuristic, not diagnostic).
    let score: Int

    var classifiedCount: Int { optimalCount + inRangeCount + outOfRangeCount }
}

/// Rollup of statuses within one category.
struct CategoryRollup: Identifiable {
    let category: MarkerCategory
    var optimal: Int
    var inRange: Int
    var outOfRange: Int
    var id: String { category.rawValue }
    var total: Int { optimal + inRange + outOfRange }
}

/// Per-marker latest snapshot (used by dashboards and insights).
struct MarkerSnapshot: Identifiable {
    let marker: Biomarker
    let assessment: RangeAssessment
    let drawDate: Date
    var id: String { marker.id }
}

/// Pure aggregation engine. All divisions guarded.
enum StatsEngine {

    /// Build a summary for a set of results from the same draw.
    static func summarize(panelResults: [LabResult], sex: BiologicalSex) -> PanelSummary? {
        guard let first = panelResults.first else { return nil }
        var optimal = 0, inRange = 0, out = 0
        var scoreAccum = 0.0
        var scored = 0

        for r in panelResults {
            guard let marker = r.marker else { continue }
            let a = RangeEngine.assess(marker: marker, rawValue: r.value, rawUnit: r.unitRaw, sex: sex)
            switch a.status {
            case .optimal: optimal += 1
            case .inRange, .belowOptimal: inRange += 1
            case .low, .high: out += 1
            }
            scoreAccum += markerScore(a.status)
            scored += 1
        }

        let score: Int
        if scored > 0 {
            score = Int((scoreAccum / Double(scored)).rounded())
        } else {
            score = 0
        }

        return PanelSummary(
            panelId: first.panelId,
            drawDate: first.drawDate,
            labName: first.labName,
            resultCount: panelResults.count,
            optimalCount: optimal,
            inRangeCount: inRange,
            outOfRangeCount: out,
            score: min(100, max(0, score))
        )
    }

    private static func markerScore(_ status: MarkerStatus) -> Double {
        switch status {
        case .optimal: return 100
        case .inRange: return 80
        case .belowOptimal: return 65
        case .high, .low: return 35
        }
    }

    /// Category rollups for a set of latest snapshots.
    static func categoryRollups(from snapshots: [MarkerSnapshot]) -> [CategoryRollup] {
        var map: [MarkerCategory: CategoryRollup] = [:]
        for s in snapshots {
            var roll = map[s.marker.category] ?? CategoryRollup(category: s.marker.category, optimal: 0, inRange: 0, outOfRange: 0)
            switch s.assessment.status {
            case .optimal: roll.optimal += 1
            case .inRange, .belowOptimal: roll.inRange += 1
            case .low, .high: roll.outOfRange += 1
            }
            map[s.marker.category] = roll
        }
        return MarkerCategory.allCases.compactMap { map[$0] }
    }

    /// Fraction (0…1) of classified markers that are in standard range or better.
    static func inRangeFraction(optimal: Int, inRange: Int, outOfRange: Int) -> Double {
        let total = optimal + inRange + outOfRange
        guard total > 0 else { return 0 }
        return Double(optimal + inRange) / Double(total)
    }

    static func optimalFraction(optimal: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(optimal) / Double(total)
    }
}
