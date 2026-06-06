import Foundation

/// Pure, testable baker's-percentage engine. No SwiftData, no SwiftUI — just value types
/// in and value types out, so the math can be reasoned about and unit-tested in isolation.
///
/// Baker's percentages express every ingredient as a percentage of the *total flour*
/// weight, where flour itself is defined as 100%. The subtlety this engine handles
/// correctly is the **levain** (pre-ferment / starter): it is itself part flour and part
/// water, so its mass must be split back into flour and water when computing the dough's
/// *true* hydration. All inputs are guarded against zero/negative values so a malformed
/// formula yields guidance, never a crash or a divide-by-zero.
enum BakersMath {

    // MARK: - Inputs

    /// A minimal value-type view of one ingredient row, decoupled from SwiftData.
    struct Row: Identifiable, Equatable {
        var id: UUID
        var name: String
        var role: Role
        /// Percentage of total flour (flour rows sum to 100).
        var percent: Double
        /// For levain rows: hydration of the pre-ferment as a percentage.
        var levainHydration: Double

        init(id: UUID = UUID(), name: String, role: Role,
             percent: Double, levainHydration: Double = 100) {
            self.id = id
            self.name = name
            self.role = role
            self.percent = max(0, percent)
            self.levainHydration = max(0, levainHydration)
        }
    }

    /// What the baker is targeting when scaling a formula.
    enum Target: Equatable {
        /// Solve so the finished dough weighs this many grams.
        case totalDough(grams: Double)
        /// Solve so the dough divides into this many loaves of this size (grams each).
        case loaves(count: Int, gramsEach: Double)

        /// The total dough weight this target implies, always > 0 (clamped).
        var totalGrams: Double {
            switch self {
            case .totalDough(let grams):
                return max(1, grams)
            case .loaves(let count, let gramsEach):
                return max(1, Double(max(1, count)) * max(1, gramsEach))
            }
        }
    }

    // MARK: - Outputs

    /// A solved ingredient row with absolute grams attached.
    struct ResolvedRow: Identifiable, Equatable {
        var id: UUID
        var name: String
        var role: Role
        var percent: Double
        var grams: Double
        /// For levain rows, the flour portion of its grams (else 0).
        var levainFlourGrams: Double
        /// For levain rows, the water portion of its grams (else 0).
        var levainWaterGrams: Double
    }

    /// The full solved formula: per-row grams plus the headline figures bakers care about.
    struct Result: Equatable {
        var rows: [ResolvedRow]
        var totalDoughGrams: Double
        /// Sum of ALL flour, including flour carried by the levain.
        var totalFlourGrams: Double
        /// Sum of ALL water, including water carried by the levain.
        var totalWaterGrams: Double
        var totalSaltGrams: Double
        var totalLevainGrams: Double
        var totalOtherGrams: Double
        /// True hydration = total water / total flour × 100.
        var hydrationPercent: Double
        /// Salt as a percentage of total flour.
        var saltPercent: Double
        /// Levain as a percentage of total flour (pre-fermented flour ratio in spirit).
        var levainPercent: Double
        /// True when the formula has no flour at all — UI should show guidance, not figures.
        var hasFlour: Bool

        static let empty = Result(rows: [], totalDoughGrams: 0, totalFlourGrams: 0,
                                  totalWaterGrams: 0, totalSaltGrams: 0, totalLevainGrams: 0,
                                  totalOtherGrams: 0, hydrationPercent: 0, saltPercent: 0,
                                  levainPercent: 0, hasFlour: false)
    }

    // MARK: - Solver

    /// Solve a formula's rows against a target into absolute grams plus headline figures.
    ///
    /// The sum of every row's percentage (the "total percentage") maps to the total dough
    /// weight. So each gram value is `target.totalGrams × percent / totalPercent`, and the
    /// flour base is `target.totalGrams × 100 / totalPercent`. From there levain rows are
    /// decomposed into their flour/water portions and folded into the true hydration.
    static func solve(rows: [Row], target: Target) -> Result {
        let totalPercent = rows.reduce(0.0) { $0 + max(0, $1.percent) }
        // A formula with no positive percentages can't be scaled meaningfully.
        guard totalPercent > 0 else { return .empty }

        let totalDough = target.totalGrams
        let perPercentGrams = totalDough / totalPercent

        var resolved: [ResolvedRow] = []
        resolved.reserveCapacity(rows.count)

        var flour = 0.0
        var water = 0.0
        var salt = 0.0
        var levain = 0.0
        var other = 0.0

        for row in rows {
            let grams = max(0, row.percent) * perPercentGrams
            var levFlour = 0.0
            var levWater = 0.0

            switch row.role {
            case .flour:
                flour += grams
            case .water:
                water += grams
            case .salt:
                salt += grams
            case .levain:
                levain += grams
                // Split the levain into flour + water at its own hydration h:
                // flour = grams / (1 + h/100), water = grams − flour.
                let h = max(0, row.levainHydration) / 100.0
                levFlour = grams / (1.0 + h)
                levWater = grams - levFlour
                flour += levFlour
                water += levWater
            case .other:
                other += grams
            }

            resolved.append(ResolvedRow(id: row.id, name: row.name, role: row.role,
                                        percent: row.percent, grams: grams,
                                        levainFlourGrams: levFlour,
                                        levainWaterGrams: levWater))
        }

        let hasFlour = flour > 0
        let hydration = hasFlour ? (water / flour * 100.0) : 0
        let saltPct = hasFlour ? (salt / flour * 100.0) : 0
        let levainPct = hasFlour ? (levain / flour * 100.0) : 0

        return Result(rows: resolved,
                      totalDoughGrams: totalDough,
                      totalFlourGrams: flour,
                      totalWaterGrams: water,
                      totalSaltGrams: salt,
                      totalLevainGrams: levain,
                      totalOtherGrams: other,
                      hydrationPercent: hydration,
                      saltPercent: saltPct,
                      levainPercent: levainPct,
                      hasFlour: hasFlour)
    }

    // MARK: - Hydration retargeting

    /// Adjust water rows so the solved formula reaches `targetHydration` (in %), keeping
    /// flour and levain fixed. Returns a new set of rows; the direct-water percentage is
    /// recomputed to account for the water the levain already contributes.
    ///
    /// Required direct water grams = targetHydration% × totalFlour − levainWater. If the
    /// levain alone already exceeds the target, direct water clamps to 0 (can't remove
    /// water that's locked inside the pre-ferment).
    static func retargetHydration(rows: [Row], to targetHydration: Double,
                                  totalDough: Double) -> [Row] {
        let safeTarget = max(0, targetHydration)
        let result = solve(rows: rows, target: .totalDough(grams: max(1, totalDough)))
        guard result.hasFlour else { return rows }

        // Water already carried by levain, in the same gram basis as `result`.
        let levainWater = result.rows.reduce(0.0) { $0 + $1.levainWaterGrams }
        let neededTotalWater = safeTarget / 100.0 * result.totalFlourGrams
        let neededDirectWater = max(0, neededTotalWater - levainWater)

        // Convert that gram figure back into a baker's percentage of total flour.
        guard result.totalFlourGrams > 0 else { return rows }
        let newWaterPercent = neededDirectWater / result.totalFlourGrams * 100.0

        // Distribute across existing water rows proportionally; if none, the caller
        // is expected to add a water row, so we leave rows unchanged.
        let waterRows = rows.filter { $0.role == .water }
        let currentWaterPercentSum = waterRows.reduce(0.0) { $0 + max(0, $1.percent) }

        return rows.map { row in
            guard row.role == .water else { return row }
            var copy = row
            if currentWaterPercentSum > 0 {
                copy.percent = newWaterPercent * (max(0, row.percent) / currentWaterPercentSum)
            } else {
                // Single implicit water row gets the whole figure.
                copy.percent = newWaterPercent
            }
            return copy
        }
    }

    // MARK: - Weight ↔ loaf scaling

    /// Total dough grams for a loaf count at a given loaf size. Inputs clamped to ≥ 1.
    static func doughWeight(loafCount: Int, gramsPerLoaf: Double) -> Double {
        Double(max(1, loafCount)) * max(1, gramsPerLoaf)
    }

    /// Grams per loaf given a total dough weight and loaf count. Guarded against 0 loaves.
    static func gramsPerLoaf(totalDough: Double, loafCount: Int) -> Double {
        let count = max(1, loafCount)
        return max(0, totalDough) / Double(count)
    }

    /// Largest whole number of loaves of `gramsPerLoaf` that fit in `totalDough`
    /// (at least 1). Guards against non-positive loaf size.
    static func loafCount(totalDough: Double, gramsPerLoaf: Double) -> Int {
        guard gramsPerLoaf > 0 else { return 1 }
        return max(1, Int((max(0, totalDough) / gramsPerLoaf).rounded()))
    }

    // MARK: - Step scheduling

    /// One scheduled step: when it starts and ends in clock time.
    struct ScheduledStep: Identifiable, Equatable {
        var id: UUID
        var label: String
        var kind: StepKind
        var detail: String
        var plannedMinutes: Int
        var start: Date
        var end: Date
    }

    /// A planned step before clock times are assigned.
    struct PlannedStep: Identifiable, Equatable {
        var id: UUID
        var order: Int
        var label: String
        var kind: StepKind
        var detail: String
        var plannedMinutes: Int

        init(id: UUID = UUID(), order: Int, label: String, kind: StepKind,
             detail: String = "", plannedMinutes: Int) {
            self.id = id
            self.order = order
            self.label = label
            self.kind = kind
            self.detail = detail
            self.plannedMinutes = max(0, plannedMinutes)
        }
    }

    /// Lay clock times across a timeline.
    ///
    /// - `fromFinish == false`: schedule forward — the first step starts at `anchor`,
    ///   each subsequent step begins when the previous ends.
    /// - `fromFinish == true`: schedule backward — the last step ends at `anchor`,
    ///   walking earlier so the whole bake *finishes* at the target time.
    ///
    /// Durations are clamped to ≥ 0; order is honored by sorting on `order`.
    static func schedule(steps: [PlannedStep], anchor: Date, fromFinish: Bool) -> [ScheduledStep] {
        let ordered = steps.sorted { $0.order < $1.order }
        guard !ordered.isEmpty else { return [] }

        if fromFinish {
            // Walk backward from the finish, then restore chronological order.
            var cursor = anchor
            var reversed: [ScheduledStep] = []
            for step in ordered.reversed() {
                let minutes = max(0, step.plannedMinutes)
                let start = cursor.addingTimeInterval(TimeInterval(-minutes * 60))
                reversed.append(ScheduledStep(id: step.id, label: step.label, kind: step.kind,
                                              detail: step.detail, plannedMinutes: minutes,
                                              start: start, end: cursor))
                cursor = start
            }
            return reversed.reversed()
        } else {
            var cursor = anchor
            var out: [ScheduledStep] = []
            for step in ordered {
                let minutes = max(0, step.plannedMinutes)
                let end = cursor.addingTimeInterval(TimeInterval(minutes * 60))
                out.append(ScheduledStep(id: step.id, label: step.label, kind: step.kind,
                                         detail: step.detail, plannedMinutes: minutes,
                                         start: cursor, end: end))
                cursor = end
            }
            return out
        }
    }

    // MARK: - Formatting helpers

    /// Round grams to a sensible precision for display: whole grams ≥ 100, one decimal below.
    static func displayGrams(_ grams: Double) -> String {
        guard grams.isFinite else { return "—" }
        let v = max(0, grams)
        if v >= 100 { return String(Int(v.rounded())) }
        if v >= 10 { return String(format: "%.1f", v) }
        return String(format: "%.1f", v)
    }

    /// Round a percentage for display (one decimal, trailing zero trimmed).
    static func displayPercent(_ percent: Double) -> String {
        guard percent.isFinite else { return "—" }
        let v = max(0, percent)
        if v == v.rounded() { return String(Int(v)) }
        return String(format: "%.1f", v)
    }

    /// Humanize a duration in minutes as e.g. "4h 30m" or "45m". Guards negatives.
    static func durationString(minutes: Int) -> String {
        let m = max(0, minutes)
        let h = m / 60
        let r = m % 60
        if h == 0 { return "\(r)m" }
        if r == 0 { return "\(h)h" }
        return "\(h)h \(r)m"
    }
}
