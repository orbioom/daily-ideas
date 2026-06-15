import SwiftUI
import SwiftData
import Charts

/// Stats: average time-to-dismiss, snoozes per week, wake-time consistency, missions
/// completed, plus Swift Charts. Free users see the last 7 days; Pro sees everything.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WakeLog.firedAt, order: .reverse) private var logs: [WakeLog]
    @AppStorage("isPro") private var isPro = false

    @State private var summary: StatsSummary?
    @State private var computing = false
    @State private var paywallReason: PaywallReason?

    /// Logs visible to this tier.
    private var visibleLogs: [WakeLog] {
        guard !isPro else { return logs }
        let cutoff = Calendar.current.date(byAdding: .day, value: -Pro.freeStatsDays, to: Date()) ?? .distantPast
        return logs.filter { $0.firedAt >= cutoff }
    }

    var body: some View {
        NavigationStack {
            Group {
                if logs.isEmpty {
                    EmptyStateView(symbol: "chart.bar",
                                   title: "No wake-ups yet",
                                   message: "Dismiss an alarm (or run a test ring) and your wake-up stats will appear here.")
                        .frame(maxHeight: .infinity)
                } else if computing || summary == nil {
                    loading
                } else if let s = summary {
                    content(s)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .task(id: "\(visibleLogs.count)-\(isPro)") { await recompute() }
    }

    private var loading: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.accent)
            Text("Crunching your wake-ups…")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Computing stats")
    }

    private func content(_ s: StatsSummary) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                tiles(s)
                dismissTrendCard(s)
                snoozeCard(s)
                consistencyCard(s)
                if !isPro { historyUpsell }
                recentCard
            }
            .padding(16)
        }
    }

    // MARK: Tiles

    private func tiles(_ s: StatsSummary) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                tile("Avg dismiss", formatDuration(s.avgSecondsToDismiss), "stopwatch", Theme.accent)
                tile("Avg snoozes", String(format: "%.1f", s.avgSnoozes), "zzz", Theme.warn)
                tile("Wake-ups", "\(s.totalWakes)", "sunrise.fill", Theme.good)
            }
            HStack(spacing: 12) {
                tile("Consistency", s.consistencyLabel, "scope", Theme.accent)
                tile("Missions", "\(s.missionsCompleted)", "brain.head.profile", Theme.good)
                tile("Best streak", "\(s.bestStreakDays)d", "flame.fill", Theme.warn)
            }
        }
    }

    private func tile(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        CardView(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint).accessibilityHidden(true)
                Text(value).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6).lineLimit(1)
                Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Charts

    private func dismissTrendCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Time to Dismiss")
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                Text("Lower is better — how long it takes you to fully wake.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                if s.dismissTrend.isEmpty {
                    miniEmpty
                } else {
                    Chart(s.dismissTrend) { p in
                        LineMark(x: .value("Wake", p.index), y: .value("Seconds", p.seconds))
                            .foregroundStyle(Theme.accent)
                            .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Wake", p.index), y: .value("Seconds", p.seconds))
                            .foregroundStyle(Theme.accent.opacity(0.15))
                            .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 170)
                    .chartXAxis(.hidden)
                    .accessibilityLabel("Time to dismiss trend across recent wake-ups")
                }
            }
        }
    }

    private func snoozeCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Snoozes per Week")
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                if s.snoozesByWeek.isEmpty {
                    miniEmpty
                } else {
                    Chart(s.snoozesByWeek) { w in
                        BarMark(x: .value("Week", w.weekLabel), y: .value("Snoozes", w.snoozes))
                            .foregroundStyle(Theme.warn.gradient)
                            .cornerRadius(4)
                    }
                    .frame(height: 170)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .accessibilityLabel("Snoozes per week bar chart")
                }
            }
        }
    }

    private func consistencyCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("When You Wake")
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                Text("Your wake clock-time spreads \(s.consistencyLabel) around your average.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                let active = s.wakeHours.filter { $0.count > 0 }
                if active.isEmpty {
                    miniEmpty
                } else {
                    Chart(active) { bin in
                        BarMark(x: .value("Hour", bin.label), y: .value("Wake-ups", bin.count))
                            .foregroundStyle(Theme.good.gradient)
                            .cornerRadius(3)
                    }
                    .frame(height: 160)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .accessibilityLabel("Distribution of wake clock-times by hour")
                }
            }
        }
    }

    private var miniEmpty: some View {
        Text("Not enough data yet.")
            .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
            .frame(maxWidth: .infinity, minHeight: 80)
    }

    // MARK: History upsell (free tier)

    private var historyUpsell: some View {
        Button { paywallReason = .statsHistory } label: {
            CardView {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 22)).foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Showing your last \(Pro.freeStatsDays) days")
                            .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                        Text("Unlock Reveille Pro for your full history.")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    ProBadge()
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Recent

    private var recentCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Wake-ups")
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                let recent = Array(visibleLogs.prefix(8))
                ForEach(recent) { log in
                    HStack(spacing: 12) {
                        Image(systemName: log.missionType.symbol)
                            .font(.system(size: 14)).foregroundStyle(Theme.accent)
                            .frame(width: 22).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(log.firedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                            Text(log.alarmLabel)
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(formatDuration(log.secondsToDismiss))
                                .font(Theme.mono(14, .semibold)).foregroundStyle(Theme.ink)
                            Text(log.snoozeCount == 0 ? "no snooze" : "\(log.snoozeCount) snooze\(log.snoozeCount == 1 ? "" : "s")")
                                .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(log.alarmLabel), dismissed in \(formatDuration(log.secondsToDismiss)), \(log.snoozeCount) snoozes")
                    if log.id != recent.last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
    }

    // MARK: Compute

    private func recompute() async {
        let source = visibleLogs
        guard !source.isEmpty else { summary = .empty(); return }
        computing = true
        let snapshot = source.map {
            WakeLogLite(date: $0.date, firedAt: $0.firedAt,
                        secondsToDismiss: $0.secondsToDismiss,
                        snoozeCount: $0.snoozeCount, missionTypeRaw: $0.missionTypeRaw)
        }
        let result = await Task.detached(priority: .userInitiated) {
            StatsSummary.build(from: snapshot)
        }.value
        summary = result
        computing = false
    }
}
