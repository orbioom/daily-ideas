import Foundation

/// A single weigh-in observation fed to the adaptive engine.
struct WeighSample: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let weightKg: Double
    /// Optional logged average daily intake (kcal) for the period leading to this weigh-in.
    let avgIntakeKcal: Double?
}

/// One point on the smoothed weight trend.
struct TrendPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let rawKg: Double
    let emaKg: Double
}

/// The adaptive recalibration result.
struct AdaptiveResult: Equatable {
    /// EMA-smoothed current weight (kg).
    let smoothedWeightKg: Double
    /// Observed weekly weight change from the trend (kg/week, signed).
    let observedWeeklyChangeKg: Double
    /// The user's estimated *actual* expenditure (kcal/day), if derivable.
    let estimatedTDEE: Double?
    /// Recommended new daily calorie target.
    let recommendedTarget: Double
    /// Change vs the previous target (recommended − previous).
    let targetDelta: Double
    /// Human-readable rationale.
    let rationale: String
    /// Confidence label based on the amount/span of data.
    let confidence: Confidence

    enum Confidence: String { case low, medium, high }
}

/// Adaptive-aggressiveness setting controls how strongly we nudge the target.
enum Aggressiveness: String, CaseIterable, Identifiable, Codable {
    case gentle
    case standard
    case aggressive
    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle:     return "Gentle"
        case .standard:   return "Standard"
        case .aggressive: return "Aggressive"
        }
    }

    /// Fraction of the calculated correction we actually apply each week.
    var factor: Double {
        switch self {
        case .gentle:     return 0.5
        case .standard:   return 0.75
        case .aggressive: return 1.0
        }
    }

    /// Cap on a single week's target change (kcal) to avoid wild swings.
    var maxStep: Double {
        switch self {
        case .gentle:     return 150
        case .standard:   return 250
        case .aggressive: return 400
        }
    }
}

/// Pure adaptive-TDEE math. Two strategies:
///  1. **Energy-balance** (preferred): when average intake is logged, the user's
///     true expenditure over a window is `avgIntake − (Δweight·7700 / days)`.
///  2. **Trend-correction** (fallback): when intake isn't logged, compare the
///     observed weekly weight change against the planned change and nudge the
///     calorie target by the kcal value of the gap.
/// Weight noise is reduced with an EMA before any rate is derived.
enum AdaptiveEngine {

    /// Exponential moving average of weight. Alpha derived from the smoothing
    /// half-life (in samples). Returns one TrendPoint per input sample.
    static func emaTrend(samples: [WeighSample], halfLife: Double = 3.0) -> [TrendPoint] {
        let sorted = samples.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }
        let hl = max(0.5, halfLife)
        let alpha = 1.0 - pow(0.5, 1.0 / hl)
        var ema = sorted[0].weightKg
        var out: [TrendPoint] = []
        for (i, s) in sorted.enumerated() {
            if i == 0 {
                ema = s.weightKg
            } else {
                ema = alpha * s.weightKg + (1 - alpha) * ema
            }
            out.append(TrendPoint(date: s.date, rawKg: s.weightKg, emaKg: ema))
        }
        return out
    }

    /// Observed weekly weight change (kg/week) from the EMA over a recent window.
    /// Uses the first and last EMA points within `windowDays`. Guards divides.
    static func observedWeeklyChangeKg(trend: [TrendPoint], windowDays: Int = 28) -> Double {
        guard trend.count >= 2 else { return 0 }
        guard let last = trend.last else { return 0 }
        let cutoff = last.date.addingTimeInterval(-Double(windowDays) * 86_400)
        let window = trend.filter { $0.date >= cutoff }
        let pts = window.count >= 2 ? window : trend
        guard let first = pts.first, let lastPt = pts.last else { return 0 }
        let days = lastPt.date.timeIntervalSince(first.date) / 86_400
        guard days > 0 else { return 0 }
        let deltaKg = lastPt.emaKg - first.emaKg
        return deltaKg / days * 7.0
    }

    /// Energy-balance TDEE estimate over the logged window. Returns nil when
    /// fewer than two intake-logged samples exist or the span is degenerate.
    static func energyBalanceTDEE(samples: [WeighSample], windowDays: Int = 28) -> Double? {
        let logged = samples
            .filter { ($0.avgIntakeKcal ?? 0) > 0 }
            .sorted { $0.date < $1.date }
        guard let last = logged.last else { return nil }
        let cutoff = last.date.addingTimeInterval(-Double(windowDays) * 86_400)
        let window = logged.filter { $0.date >= cutoff }
        let pts = window.count >= 2 ? window : logged
        guard pts.count >= 2, let first = pts.first, let lastPt = pts.last else { return nil }

        let days = lastPt.date.timeIntervalSince(first.date) / 86_400
        guard days > 0 else { return nil }

        // Average of logged intakes across the window.
        let intakes = pts.compactMap { $0.avgIntakeKcal }
        guard !intakes.isEmpty else { return nil }
        let avgIntake = intakes.reduce(0, +) / Double(intakes.count)

        // Weight change across the window from the raw endpoints (energy balance).
        let weightChangeKg = lastPt.weightKg - first.weightKg
        let tdee = avgIntake - (weightChangeKg * MacroEngine.kcalPerKg / days)
        guard tdee.isFinite, tdee > 0 else { return nil }
        return tdee
    }

    /// Produce a weekly recalibration recommendation.
    ///
    /// - Parameters:
    ///   - samples: all weigh-ins (chronological order not required).
    ///   - currentTarget: the calorie target currently in force.
    ///   - goal / plannedRatePercent / weightKg: the user's plan.
    ///   - aggressiveness: how strongly to apply the correction.
    ///   - roundTo: rounding for the recommended target.
    static func recalibrate(samples: [WeighSample],
                            currentTarget: Double,
                            goal: Goal,
                            plannedRatePercent: Double,
                            weightKg: Double,
                            aggressiveness: Aggressiveness,
                            roundTo: Int) -> AdaptiveResult? {

        let trend = emaTrend(samples: samples)
        guard let lastTrend = trend.last else { return nil }
        let smoothed = lastTrend.emaKg
        let observedWeekly = observedWeeklyChangeKg(trend: trend)

        // Planned weekly change in kg (signed).
        let plannedWeeklyKg = goal.direction * (plannedRatePercent / 100.0) * max(1, weightKg)

        // Confidence from the number & span of samples.
        let span = (trend.first.map { lastTrend.date.timeIntervalSince($0.date) } ?? 0) / 86_400
        let confidence: AdaptiveResult.Confidence
        if trend.count >= 6 && span >= 28 { confidence = .high }
        else if trend.count >= 3 && span >= 14 { confidence = .medium }
        else { confidence = .low }

        let energyTDEE = energyBalanceTDEE(samples: samples)

        var recommended = currentTarget
        var rationale: String

        if let tdee = energyTDEE {
            // Energy-balance path: re-derive the target from the measured TDEE.
            let delta = goal == .maintain
                ? 0
                : MacroEngine.dailyKcalDelta(goal: goal, ratePercent: plannedRatePercent, weightKg: weightKg)
            let idealTarget = tdee + delta
            // Move part-way from current toward the ideal target.
            let correction = (idealTarget - currentTarget) * aggressiveness.factor
            let capped = clamp(correction, to: aggressiveness.maxStep)
            recommended = currentTarget + capped
            rationale = "Your logged intake and weight trend imply a true maintenance of about \(Int(tdee.rounded())) kcal. "
            if abs(capped) < 1 {
                rationale += "Your current target already matches your plan — no change needed."
            } else {
                rationale += capped > 0
                    ? "Nudging your target up \(Int(capped.rounded())) kcal to match it."
                    : "Trimming your target \(Int((-capped).rounded())) kcal to match it."
            }
        } else {
            // Trend-correction path: compare observed vs planned weekly change.
            let gapKg = observedWeekly - plannedWeeklyKg // signed kg/week off plan
            // Convert the weekly gap to a daily kcal correction.
            // If losing slower than planned (gap > 0 on a cut), we must EAT LESS,
            // so the correction subtracts. The kcal value of the gap per day:
            let dailyKcalGap = gapKg * MacroEngine.kcalPerKg / 7.0
            // To close the gap we move the target opposite to the surplus implied.
            let rawCorrection = -dailyKcalGap * aggressiveness.factor
            let capped = clamp(rawCorrection, to: aggressiveness.maxStep)
            recommended = currentTarget + capped

            let observedDesc = describeWeekly(observedWeekly)
            let plannedDesc = describeWeekly(plannedWeeklyKg)
            if abs(capped) < 1 {
                rationale = "You're tracking your plan (\(observedDesc) vs planned \(plannedDesc)). Hold the current target."
            } else if capped < 0 {
                rationale = "You're changing \(observedDesc) — slower than the planned \(plannedDesc). Lowering your target \(Int((-capped).rounded())) kcal to get back on pace."
            } else {
                rationale = "You're changing \(observedDesc) — faster than the planned \(plannedDesc). Raising your target \(Int(capped.rounded())) kcal to protect performance."
            }
        }

        recommended = MacroEngine.roundCalories(max(0, recommended), to: roundTo)
        let targetDelta = recommended - currentTarget

        return AdaptiveResult(smoothedWeightKg: smoothed,
                              observedWeeklyChangeKg: observedWeekly,
                              estimatedTDEE: energyTDEE,
                              recommendedTarget: recommended,
                              targetDelta: targetDelta,
                              rationale: rationale,
                              confidence: confidence)
    }

    // MARK: - Projection & scheduling

    /// Estimated date to reach `goalWeightKg` at a given weekly rate (kg/week).
    /// Returns nil when the rate is zero or moving away from the goal.
    static func projectedFinishDate(currentWeightKg: Double,
                                    goalWeightKg: Double,
                                    weeklyChangeKg: Double,
                                    from start: Date = Date()) -> Date? {
        let remaining = goalWeightKg - currentWeightKg
        guard abs(remaining) > 0.05 else { return start } // essentially there
        guard abs(weeklyChangeKg) > 0.0001 else { return nil }
        // The change must move in the same direction as `remaining`.
        guard remaining.sign == weeklyChangeKg.sign else { return nil }
        let weeks = remaining / weeklyChangeKg
        guard weeks.isFinite, weeks > 0, weeks < 520 else { return nil } // cap at ~10y
        return start.addingTimeInterval(weeks * 7 * 86_400)
    }

    /// Upcoming refeed / diet-break dates: a maintenance break every `cadenceWeeks`
    /// from the cut's start, looking forward `count` occurrences.
    static func refeedSchedule(cutStart: Date,
                               cadenceWeeks: Int,
                               count: Int = 6,
                               from now: Date = Date()) -> [Date] {
        guard cadenceWeeks > 0, count > 0 else { return [] }
        var dates: [Date] = []
        var i = 1
        while dates.count < count && i < 200 {
            let d = cutStart.addingTimeInterval(Double(i * cadenceWeeks) * 7 * 86_400)
            if d >= now { dates.append(d) }
            i += 1
        }
        return dates
    }

    // MARK: - Helpers

    private static func clamp(_ value: Double, to maxAbs: Double) -> Double {
        min(max(value, -maxAbs), maxAbs)
    }

    /// Describe a signed weekly change in kg as a short phrase.
    private static func describeWeekly(_ kg: Double) -> String {
        if abs(kg) < 0.01 { return "holding steady" }
        let dir = kg < 0 ? "−" : "+"
        return "\(dir)\(String(format: "%.2f", abs(kg))) kg/wk"
    }
}
