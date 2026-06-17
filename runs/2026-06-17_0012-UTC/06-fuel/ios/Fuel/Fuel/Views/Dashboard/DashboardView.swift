import SwiftUI
import SwiftData

/// Today / Dashboard: the calorie ring, three macro bars, current phase, EMA
/// weight vs goal, next-check-in nudge and days-to-goal. Empty state routes the
/// user to build a plan.
struct DashboardView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]
    @Query(sort: \CheckIn.date, order: .forward) private var checkIns: [CheckIn]
    @Query(sort: \TargetSnapshot.date, order: .reverse) private var snapshots: [TargetSnapshot]

    @State private var goToPlan = false

    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    content(profile: profile)
                } else {
                    EmptyStateView(
                        icon: "flame.fill",
                        title: "No plan yet",
                        message: "Build your profile and goal to see your calorie target and macros.",
                        actionTitle: "Create my plan",
                        action: { goToPlan = true }
                    )
                }
            }
            .fuelScreenBackground(scheme)
            .navigationTitle("Today")
            .navigationDestination(isPresented: $goToPlan) {
                PlanView()
            }
        }
    }

    @ViewBuilder
    private func content(profile: Profile) -> some View {
        let computed = PlanCalculator.target(for: profile, settings: settings)
        let activeTarget = PlanCalculator.activeTarget(snapshots: snapshots, computed: computed)
        // Recompute macros against the active (possibly adapted) target.
        let macros = MacroSplit.compute(dietStyle: profile.dietStyle,
                                        calories: activeTarget,
                                        weightKg: profile.currentWeightKg,
                                        bodyFatPercent: profile.bodyFatPercent,
                                        customProteinPerKg: profile.customProteinPerKg,
                                        customFatPerKg: profile.customFatPerKg)
        let trend = AdaptiveEngine.emaTrend(samples: checkIns.map(\.sample))
        let smoothed = trend.last?.emaKg ?? profile.currentWeightKg
        let weekly = AdaptiveEngine.observedWeeklyChangeKg(trend: trend)
        let finish = AdaptiveEngine.projectedFinishDate(currentWeightKg: smoothed,
                                                        goalWeightKg: profile.goalWeightKg,
                                                        weeklyChangeKg: weekly)

        ScrollView {
            VStack(spacing: 16) {
                // Phase + greeting
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(FuelTheme.primaryText(scheme))
                        Text("Here's your fuel for today")
                            .font(.subheadline)
                            .foregroundStyle(FuelTheme.secondaryText(scheme))
                    }
                    Spacer()
                    PhasePill(goal: profile.goal, ratePercent: profile.goalRatePercent)
                }

                // Calorie ring + macro bars
                FuelCard {
                    VStack(spacing: 18) {
                        CalorieRing(calories: activeTarget, fraction: 1.0)
                            .padding(.top, 4)
                        MacroBarsView(macros: macros)
                    }
                }

                // Stat grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(title: "Trend weight",
                             value: Fmt.weight(smoothed, unit: settings.weightUnit),
                             systemImage: "scalemass",
                             tint: FuelTheme.orange)
                    StatTile(title: "Goal weight",
                             value: Fmt.weight(profile.goalWeightKg, unit: settings.weightUnit),
                             systemImage: "flag.checkered",
                             tint: FuelTheme.teal)
                    StatTile(title: "Weekly change",
                             value: Fmt.weeklyChange(weekly, unit: settings.weightUnit),
                             systemImage: profile.goal.symbol,
                             tint: changeTint(weekly: weekly, goal: profile.goal))
                    StatTile(title: "Days to goal",
                             value: daysToGoal(finish),
                             systemImage: "calendar",
                             tint: FuelTheme.positive)
                }

                // Next check-in nudge
                checkInNudge

                // Trend chart preview
                if trend.count >= 2 {
                    FuelCard {
                        VStack(alignment: .leading, spacing: 10) {
                            FuelSectionHeader(title: "Weight trend", systemImage: "chart.xyaxis.line")
                            WeightTrendChart(trend: trend,
                                             goalWeightKg: profile.goalWeightKg,
                                             unit: settings.weightUnit)
                        }
                    }
                }

                disclaimer
            }
            .padding(16)
        }
    }

    private var checkInNudge: some View {
        let last = checkIns.last?.date
        let due = last?.addingTimeInterval(7 * 86_400)
        let overdue = due.map { $0 <= Date() } ?? true
        return FuelCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: overdue ? "bell.badge.fill" : "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(overdue ? FuelTheme.orange : FuelTheme.positive)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(overdue ? "Check-in due" : "Next check-in")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FuelTheme.primaryText(scheme))
                    Text(dueText(due: due, overdue: overdue))
                        .font(.caption)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var disclaimer: some View {
        Text("Estimates only — not medical advice. Consult a professional before major diet changes.")
            .font(.caption2)
            .foregroundStyle(FuelTheme.secondaryText(scheme))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    // MARK: - Helpers

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func dueText(due: Date?, overdue: Bool) -> String {
        guard let due else { return "Log your first weigh-in to start adapting." }
        return overdue
            ? "It's been a week — weigh in to keep your target accurate (\(Fmt.relativeDue(due)))."
            : "Weigh in \(Fmt.relativeDue(due))."
    }

    private func daysToGoal(_ finish: Date?) -> String {
        guard let finish else { return "—" }
        let days = Int((finish.timeIntervalSince(Date()) / 86_400).rounded())
        if days <= 0 { return "Reached" }
        return "\(days)"
    }

    private func changeTint(weekly: Double, goal: Goal) -> Color {
        switch goal {
        case .cut: return weekly < 0 ? FuelTheme.positive : FuelTheme.warning
        case .bulk: return weekly > 0 ? FuelTheme.positive : FuelTheme.warning
        case .maintain: return abs(weekly) < 0.2 ? FuelTheme.positive : FuelTheme.warning
        }
    }
}
