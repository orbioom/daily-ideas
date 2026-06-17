import SwiftUI
import SwiftData

/// Check-ins: log weigh-ins, view history (edit/delete), see the adaptive
/// recalibration result and apply a new target. Charts the weight trend.
struct CheckInsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro

    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]
    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]
    @Query(sort: \TargetSnapshot.date, order: .reverse) private var snapshots: [TargetSnapshot]

    @State private var editing: CheckIn?
    @State private var showingNew = false
    @State private var showPaywall = false
    @State private var appliedBanner = false

    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    content(profile: profile)
                } else {
                    EmptyStateView(
                        icon: "scalemass.fill",
                        title: "Create a plan first",
                        message: "Set up your profile on the Plan tab, then log weekly weigh-ins here to adapt your target."
                    )
                }
            }
            .fuelScreenBackground(scheme)
            .navigationTitle("Check-ins")
            .toolbar {
                if profile != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingNew = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .accessibilityLabel("Add check-in")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                CheckInEditorSheet(existing: nil, defaultWeightKg: profile?.currentWeightKg ?? 80)
            }
            .sheet(item: $editing) { item in
                CheckInEditorSheet(existing: item, defaultWeightKg: item.weightKg)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private func content(profile: Profile) -> some View {
        let trend = AdaptiveEngine.emaTrend(samples: checkIns.map(\.sample))
        let computed = PlanCalculator.target(for: profile, settings: settings)
        let activeTarget = PlanCalculator.activeTarget(snapshots: snapshots, computed: computed)
        let visibleCheckIns = pro.isPro ? checkIns : Array(checkIns.prefix(ProStore.freeHistoryLimit))

        ScrollView {
            VStack(spacing: 16) {
                if checkIns.isEmpty {
                    EmptyStateView(
                        icon: "scalemass",
                        title: "No check-ins yet",
                        message: "Log your first weigh-in to start charting your trend and adapting your target.",
                        actionTitle: "Log a weigh-in",
                        action: { showingNew = true }
                    )
                } else {
                    // Trend chart
                    FuelCard {
                        VStack(alignment: .leading, spacing: 10) {
                            FuelSectionHeader(title: "Weight trend", systemImage: "chart.xyaxis.line")
                            if trend.count >= 2 {
                                WeightTrendChart(trend: trend,
                                                 goalWeightKg: profile.goalWeightKg,
                                                 unit: settings.weightUnit)
                            } else {
                                Text("Add at least two weigh-ins to see your trend line.")
                                    .font(.subheadline)
                                    .foregroundStyle(FuelTheme.secondaryText(scheme))
                                    .padding(.vertical, 20)
                            }
                        }
                    }

                    // Adaptive recalibration (Pro)
                    AdaptiveCard(profile: profile,
                                 checkIns: checkIns,
                                 activeTarget: activeTarget,
                                 isPro: pro.isPro,
                                 appliedBanner: appliedBanner,
                                 onUnlock: { showPaywall = true },
                                 onApply: { result in applyRecommendation(result, profile: profile) })

                    // History list
                    historyCard(visible: visibleCheckIns, total: checkIns.count)
                }
            }
            .padding(16)
        }
    }

    private func historyCard(visible: [CheckIn], total: Int) -> some View {
        FuelCard {
            VStack(alignment: .leading, spacing: 12) {
                FuelSectionHeader(title: "History", systemImage: "clock.arrow.circlepath")
                LazyVStack(spacing: 0) {
                    ForEach(visible) { c in
                        CheckInRow(checkIn: c, unit: settings.weightUnit)
                            .contentShape(Rectangle())
                            .onTapGesture { editing = c }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { delete(c) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        if c.id != visible.last?.id {
                            Divider().overlay(FuelTheme.hairline(scheme))
                        }
                    }
                }
                if !pro.isPro && total > visible.count {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("\(total - visible.count) older check-ins — unlock with Pro")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FuelTheme.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Actions

    private func delete(_ checkIn: CheckIn) {
        modelContext.delete(checkIn)
        try? modelContext.save()
        Haptics.warning(settings.hapticsEnabled)
    }

    private func applyRecommendation(_ result: AdaptiveResult, profile: Profile) {
        // Recompute macros for the new target and write a snapshot. Also update
        // the profile's current weight to the smoothed value so future plans track.
        let macros = MacroSplit.compute(dietStyle: profile.dietStyle,
                                        calories: result.recommendedTarget,
                                        weightKg: profile.currentWeightKg,
                                        bodyFatPercent: profile.bodyFatPercent,
                                        customProteinPerKg: profile.customProteinPerKg,
                                        customFatPerKg: profile.customFatPerKg)
        // Log the measured TDEE when available; otherwise infer it from the new
        // target by removing the planned deficit/surplus, so the Insights chart
        // still has a sensible expenditure value.
        let inferredTDEE = result.estimatedTDEE ?? (result.recommendedTarget
            - MacroEngine.dailyKcalDelta(goal: profile.goal,
                                         ratePercent: profile.goalRatePercent,
                                         weightKg: result.smoothedWeightKg))
        let snap = TargetSnapshot(date: Date(),
                                  calorieTarget: result.recommendedTarget,
                                  proteinG: macros.proteinG,
                                  carbG: macros.carbG,
                                  fatG: macros.fatG,
                                  estimatedTDEE: inferredTDEE,
                                  rationale: result.rationale)
        // Track latest smoothed weight on the profile.
        profile.currentWeightKg = result.smoothedWeightKg
        modelContext.insert(snap)
        try? modelContext.save()
        Haptics.success(settings.hapticsEnabled)
        withAnimation { appliedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation { appliedBanner = false }
        }
    }
}

/// A single check-in row in the history list.
private struct CheckInRow: View {
    @Environment(\.colorScheme) private var scheme
    let checkIn: CheckIn
    let unit: WeightUnit

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Fmt.date(checkIn.date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FuelTheme.primaryText(scheme))
                if !checkIn.note.isEmpty {
                    Text(checkIn.note)
                        .font(.caption)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                        .lineLimit(1)
                } else if let intake = checkIn.avgDailyIntakeKcal {
                    Text("Logged \(Fmt.kcal(intake)) kcal/day")
                        .font(.caption)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                }
            }
            Spacer()
            Text(Fmt.weight(checkIn.weightKg, unit: unit))
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(FuelTheme.orange)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Fmt.date(checkIn.date)), \(Fmt.weight(checkIn.weightKg, unit: unit))")
        .accessibilityHint("Double-tap to edit")
    }
}
