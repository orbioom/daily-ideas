import SwiftUI
import SwiftData

/// Hero tab: tonight's recommended bedtime, sleep-debt status, consistency,
/// and a quick jump into the wind-down routine. Shows a brief computed-loading
/// state while metrics are derived.
struct TonightView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SleepLog.night, order: .reverse) private var logs: [SleepLog]
    @Query private var settingsList: [SleepSettings]
    @Query private var windDownItems: [WindDownItem]

    @State private var metrics: SleepMetrics?
    @State private var isComputing = true
    @State private var showLogSheet = false
    @State private var now = Date()

    private var settings: SleepSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground()
                content
            }
            .navigationTitle("Tonight")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Log a night of sleep")
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogEditorView(mode: .create)
            }
        }
        .task(id: logs.count) { await recompute() }
        .onChange(of: settingsList.first?.goalHours) { _, _ in Task { await recompute() } }
        .onChange(of: settingsList.first?.chronotypeRaw) { _, _ in Task { await recompute() } }
        .onChange(of: settingsList.first?.anchorWakeTime) { _, _ in Task { await recompute() } }
    }

    @ViewBuilder
    private var content: some View {
        if isComputing && metrics == nil {
            VStack(spacing: 12) {
                ProgressView()
                Text("Reading your sleep…")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        } else if let metrics, let settings {
            ScrollView {
                VStack(spacing: 16) {
                    BedtimeHeroCard(metrics: metrics, settings: settings)
                    debtCard(metrics)
                    consistencyCard(metrics)
                    averageTile(metrics)
                    windDownPreview
                    if metrics.nightsLogged == 0 {
                        EmptyStateView(
                            symbol: "bed.double",
                            title: "No nights yet",
                            message: "Log last night to start tracking your sleep debt and rhythm.",
                            actionTitle: "Log a night",
                            action: { showLogSheet = true }
                        )
                        .driftCard()
                    }
                }
                .padding()
            }
        } else {
            EmptyStateView(
                symbol: "moon.zzz",
                title: "Getting set up",
                message: "Your sleep settings are being prepared."
            )
        }
    }

    private func debtCard(_ m: SleepMetrics) -> some View {
        let verdict = m.debtVerdict
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("14-night sleep debt", systemImage: "hourglass")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(Format.debt(m.debt))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(verdict.isGood ? Theme.good : Theme.warn)
                Spacer()
            }
            Text(verdict.text)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
            if m.debt >= 1 {
                Text("Tip: an extra hour for the next \(min(7, Int(m.debt.rounded(.up)))) nights brings you back to baseline.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .driftCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sleep debt \(Format.debt(m.debt)). \(verdict.text)")
    }

    private func consistencyCard(_ m: SleepMetrics) -> some View {
        HStack(spacing: 18) {
            RingGauge(
                progress: Double(m.consistency) / 100.0,
                centerTitle: "\(m.consistency)",
                centerSubtitle: "score",
                tint: Theme.dusk
            )
            .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: 6) {
                Text("Consistency")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                Text(m.consistencyVerdict)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("How tightly your bed and wake times cluster across 14 nights. Steadier rhythm pays down debt faster.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .driftCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Consistency score \(m.consistency) out of 100. \(m.consistencyVerdict)")
    }

    private func averageTile(_ m: SleepMetrics) -> some View {
        StatCard(
            title: "Avg sleep · 14 nights",
            value: Format.duration(m.avgDuration),
            caption: "Goal \(Format.duration(m.goalHours)) · quality \(String(format: "%.1f", m.avgQuality))/5",
            symbol: "bed.double.fill",
            tint: Theme.night
        )
    }

    private var windDownPreview: some View {
        let enabled = windDownItems.filter { $0.isEnabled }
        let tonightNight = Calendar.current.startOfDay(for: now)
        let done = enabled.filter { $0.isDone(on: tonightNight) }.count
        return NavigationLink {
            RoutineView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "checklist")
                    .font(.title2)
                    .foregroundStyle(Theme.dawn)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Wind-down routine")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(enabled.isEmpty ? "Add steps to your routine" : "\(done) of \(enabled.count) steps done tonight")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .driftCard()
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func recompute() async {
        isComputing = true
        now = Date()
        let settings = SettingsStore.current(context)
        // Small yield so the loading state is visible on cold start; keeps UI responsive.
        try? await Task.sleep(nanoseconds: 120_000_000)
        metrics = SleepMetrics.make(logs: logs, settings: settings, now: now)
        isComputing = false
    }
}

/// Big bedtime suggestion card with chronotype context.
private struct BedtimeHeroCard: View {
    let metrics: SleepMetrics
    let settings: SleepSettings

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: settings.chronotype.symbol)
                    .foregroundStyle(settings.chronotype.tint)
                    .accessibilityHidden(true)
                Text("\(settings.chronotype.title) chronotype")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: 4) {
                Text("Aim for lights-out at")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Text(Format.clock(metrics.suggestedBedtime, use24h: settings.use24HourClock))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

            HStack(spacing: 18) {
                miniStat(
                    label: "Wind-down",
                    value: Format.clock(metrics.windDownStart, use24h: settings.use24HourClock),
                    symbol: "wind"
                )
                Divider().frame(height: 32)
                miniStat(
                    label: "Wake",
                    value: Format.clock(settings.anchorWakeTime, use24h: settings.use24HourClock),
                    symbol: "sunrise.fill"
                )
                Divider().frame(height: 32)
                miniStat(
                    label: "Sleep",
                    value: Format.duration(metrics.goalHours),
                    symbol: "moon.fill"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.nightGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Theme.dusk.opacity(0.3), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Suggested bedtime \(Format.clock(metrics.suggestedBedtime, use24h: settings.use24HourClock)), wind-down at \(Format.clock(metrics.windDownStart, use24h: settings.use24HourClock)), wake at \(Format.clock(settings.anchorWakeTime, use24h: settings.use24HourClock))")
    }

    private func miniStat(label: String, value: String, symbol: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}
