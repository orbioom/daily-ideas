import SwiftUI
import SwiftData
import Charts

/// Progress / Insights: TDEE-over-time line, target-calories history, weekly
/// weight-change bars, a macro-split donut, projected finish date and the
/// refeed / diet-break schedule.
struct InsightsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro

    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]
    @Query(sort: \CheckIn.date, order: .forward) private var checkIns: [CheckIn]
    @Query(sort: \TargetSnapshot.date, order: .forward) private var snapshots: [TargetSnapshot]

    @State private var showPaywall = false

    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    content(profile: profile)
                } else {
                    EmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "No insights yet",
                        message: "Create a plan and log a few check-ins to unlock your progress charts."
                    )
                }
            }
            .fuelScreenBackground(scheme)
            .navigationTitle("Insights")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private func content(profile: Profile) -> some View {
        let trend = AdaptiveEngine.emaTrend(samples: checkIns.map(\.sample))
        let weekly = AdaptiveEngine.observedWeeklyChangeKg(trend: trend)
        let smoothed = trend.last?.emaKg ?? profile.currentWeightKg
        let computed = PlanCalculator.target(for: profile, settings: settings)
        let activeTarget = PlanCalculator.activeTarget(snapshots: snapshots, computed: computed)
        let macros = MacroSplit.compute(dietStyle: profile.dietStyle,
                                        calories: activeTarget,
                                        weightKg: profile.currentWeightKg,
                                        bodyFatPercent: profile.bodyFatPercent,
                                        customProteinPerKg: profile.customProteinPerKg,
                                        customFatPerKg: profile.customFatPerKg)
        let observedFinish = AdaptiveEngine.projectedFinishDate(currentWeightKg: smoothed,
                                                               goalWeightKg: profile.goalWeightKg,
                                                               weeklyChangeKg: weekly)
        let plannedWeekly = profile.goal.direction * (profile.goalRatePercent / 100.0) * profile.currentWeightKg
        let plannedFinish = AdaptiveEngine.projectedFinishDate(currentWeightKg: smoothed,
                                                              goalWeightKg: profile.goalWeightKg,
                                                              weeklyChangeKg: plannedWeekly)

        ScrollView {
            VStack(spacing: 16) {
                if checkIns.isEmpty && snapshots.count < 2 {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "Not enough data",
                        message: "Log check-ins and save plan changes to see how your targets and expenditure evolve."
                    )
                } else {
                    projectionCard(observed: observedFinish, planned: plannedFinish, weekly: weekly, profile: profile)
                    macroDonutCard(macros: macros)
                    if snapshots.count >= 2 {
                        tdeeCard
                        targetHistoryCard
                    }
                    if trend.count >= 2 {
                        weeklyChangeCard(trend: trend)
                    }
                    refeedCard(profile: profile)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Projection

    private func projectionCard(observed: Date?, planned: Date?, weekly: Double, profile: Profile) -> some View {
        FuelCard {
            VStack(alignment: .leading, spacing: 12) {
                FuelSectionHeader(title: "Projected finish", systemImage: "flag.checkered")
                HStack(spacing: 12) {
                    StatTile(title: "At your pace",
                             value: finishText(observed),
                             systemImage: "figure.walk",
                             tint: FuelTheme.orange)
                    StatTile(title: "At planned pace",
                             value: finishText(planned),
                             systemImage: "calendar",
                             tint: FuelTheme.teal)
                }
                Text(projectionNote(observed: observed, profile: profile, weekly: weekly))
                    .font(.caption)
                    .foregroundStyle(FuelTheme.secondaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func projectionNote(observed: Date?, profile: Profile, weekly: Double) -> String {
        guard observed != nil else {
            if profile.goal == .maintain { return "You're maintaining — no finish date to project." }
            return "Your current trend isn't moving toward your goal weight yet. Keep logging."
        }
        return "Based on your smoothed \(Fmt.weeklyChange(weekly, unit: settings.weightUnit)) trend toward \(Fmt.weight(profile.goalWeightKg, unit: settings.weightUnit))."
    }

    // MARK: - Macro donut

    private func macroDonutCard(macros: MacroTargets) -> some View {
        let slices: [(String, Double, Color)] = [
            ("Protein", macros.proteinKcal, FuelTheme.protein),
            ("Carbs", macros.carbKcal, FuelTheme.carbs),
            ("Fat", macros.fatKcal, FuelTheme.fat)
        ]
        return FuelCard {
            VStack(alignment: .leading, spacing: 12) {
                FuelSectionHeader(title: "Macro split", systemImage: "chart.pie.fill")
                HStack(spacing: 20) {
                    Chart(slices, id: \.0) { slice in
                        SectorMark(
                            angle: .value("kcal", slice.1),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(slice.2)
                        .cornerRadius(3)
                    }
                    .frame(width: 130, height: 130)
                    .accessibilityLabel("Macro split donut")
                    .accessibilityValue("Protein \(Int(macros.proteinPercent.rounded())) percent, carbs \(Int(macros.carbPercent.rounded())) percent, fat \(Int(macros.fatPercent.rounded())) percent")

                    VStack(alignment: .leading, spacing: 10) {
                        legend("Protein", macros.proteinG, macros.proteinPercent, FuelTheme.protein)
                        legend("Carbs", macros.carbG, macros.carbPercent, FuelTheme.carbs)
                        legend("Fat", macros.fatG, macros.fatPercent, FuelTheme.fat)
                    }
                }
            }
        }
    }

    private func legend(_ name: String, _ grams: Double, _ pct: Double, _ color: Color) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 0) {
                Text(name).font(.caption.weight(.semibold)).foregroundStyle(FuelTheme.primaryText(scheme))
                Text("\(Fmt.grams(grams)) · \(Fmt.percentWhole(pct))")
                    .font(.caption2).foregroundStyle(FuelTheme.secondaryText(scheme))
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - TDEE over time

    private var tdeeCard: some View {
        FuelCard {
            VStack(alignment: .leading, spacing: 10) {
                FuelSectionHeader(title: "Estimated TDEE over time", systemImage: "bolt.fill")
                Chart(snapshots, id: \.id) { snap in
                    LineMark(
                        x: .value("Date", snap.date),
                        y: .value("TDEE", snap.estimatedTDEE)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(FuelTheme.teal)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    PointMark(
                        x: .value("Date", snap.date),
                        y: .value("TDEE", snap.estimatedTDEE)
                    )
                    .foregroundStyle(FuelTheme.teal)
                    .symbolSize(26)
                }
                .frame(height: 180)
                .accessibilityLabel("Estimated TDEE over time")
                .accessibilityValue(tdeeSummary)
            }
        }
    }

    private var tdeeSummary: String {
        guard let first = snapshots.first, let last = snapshots.last else { return "No data" }
        return "From \(Fmt.kcal(first.estimatedTDEE)) to \(Fmt.kcal(last.estimatedTDEE)) kcal"
    }

    // MARK: - Target history

    private var targetHistoryCard: some View {
        FuelCard {
            VStack(alignment: .leading, spacing: 10) {
                FuelSectionHeader(title: "Calorie target history", systemImage: "flame.fill")
                Chart(snapshots, id: \.id) { snap in
                    LineMark(
                        x: .value("Date", snap.date),
                        y: .value("Target", snap.calorieTarget)
                    )
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(FuelTheme.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    AreaMark(
                        x: .value("Date", snap.date),
                        y: .value("Target", snap.calorieTarget)
                    )
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(FuelTheme.orange.opacity(0.12))
                }
                .frame(height: 160)
                .accessibilityLabel("Calorie target history")
                .accessibilityValue(targetSummary)
            }
        }
    }

    private var targetSummary: String {
        guard let first = snapshots.first, let last = snapshots.last else { return "No data" }
        return "From \(Fmt.kcal(first.calorieTarget)) to \(Fmt.kcal(last.calorieTarget)) kcal target"
    }

    // MARK: - Weekly change bars

    private func weeklyChangeCard(trend: [TrendPoint]) -> some View {
        let bars = weeklyDeltas(trend: trend)
        return FuelCard {
            VStack(alignment: .leading, spacing: 10) {
                FuelSectionHeader(title: "Weekly weight change", systemImage: "arrow.up.arrow.down")
                if bars.isEmpty {
                    Text("Add more weigh-ins to chart week-over-week change.")
                        .font(.subheadline)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                        .padding(.vertical, 12)
                } else {
                    Chart(bars) { bar in
                        BarMark(
                            x: .value("Week", bar.date, unit: .weekOfYear),
                            y: .value("Change", settings.weightUnit.fromKg(bar.deltaKg))
                        )
                        .foregroundStyle(bar.deltaKg <= 0 ? FuelTheme.positive : FuelTheme.warning)
                        .cornerRadius(4)
                    }
                    .frame(height: 170)
                    .accessibilityLabel("Weekly weight change bars")
                    .accessibilityValue("\(bars.count) weeks charted")
                }
            }
        }
    }

    /// Week-over-week EMA deltas as bars.
    private func weeklyDeltas(trend: [TrendPoint]) -> [WeeklyDelta] {
        guard trend.count >= 2 else { return [] }
        var out: [WeeklyDelta] = []
        for i in 1..<trend.count {
            guard let prev = trend[safe: i - 1], let cur = trend[safe: i] else { continue }
            out.append(WeeklyDelta(date: cur.date, deltaKg: cur.emaKg - prev.emaKg))
        }
        return out
    }

    // MARK: - Refeed schedule (Pro)

    private func refeedCard(profile: Profile) -> some View {
        let dates = AdaptiveEngine.refeedSchedule(cutStart: profile.createdAt,
                                                  cadenceWeeks: settings.refeedCadence)
        return FuelCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    FuelSectionHeader(title: "Refeed & diet breaks", systemImage: "calendar.badge.clock")
                    if !pro.isPro {
                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(FuelTheme.orange)
                    }
                }
                if profile.goal != .cut {
                    Text("Diet breaks are scheduled during a cut. Switch your goal to a cut to plan them.")
                        .font(.subheadline)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                } else if !pro.isPro {
                    Text("Plan maintenance diet breaks every \(settings.refeedCadence) weeks to protect your cut. Unlock with Pro.")
                        .font(.subheadline)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                    Button("Unlock scheduler") { showPaywall = true }
                        .buttonStyle(FuelSecondaryButtonStyle())
                } else if dates.isEmpty {
                    Text("No upcoming breaks within the planning window.")
                        .font(.subheadline)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                } else {
                    Text("A maintenance break every \(settings.refeedCadence) weeks. Eat at maintenance for ~5–7 days to recover.")
                        .font(.caption)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                    ForEach(Array(dates.enumerated()), id: \.offset) { idx, date in
                        HStack {
                            ZStack {
                                Circle().fill(FuelTheme.teal.opacity(0.16)).frame(width: 34, height: 34)
                                Text("\(idx + 1)").font(.subheadline.weight(.bold)).foregroundStyle(FuelTheme.tealDeep)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Diet break \(idx + 1)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(FuelTheme.primaryText(scheme))
                                Text("\(Fmt.date(date)) · \(Fmt.relativeDue(date))")
                                    .font(.caption)
                                    .foregroundStyle(FuelTheme.secondaryText(scheme))
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func finishText(_ date: Date?) -> String {
        guard let date else { return "—" }
        return Fmt.date(date)
    }
}

private struct WeeklyDelta: Identifiable {
    let id = UUID()
    let date: Date
    let deltaKg: Double
}
