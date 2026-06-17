import SwiftUI
import SwiftData
import Charts

/// Progress — e1RM trend, volume by muscle group, weekly volume, PRs. Charts gated by Pro.
struct ProgressScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(filter: #Predicate<WorkoutSession> { $0.isComplete },
           sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var snapshots: [StatsEngine.SessionSnapshot] = []
    @State private var liftNames: [String] = []
    @State private var selectedLift: String = ""
    @State private var isLoading = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Progress")
            .toolbar {
                if !isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { paywallReason = .analytics } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .task(id: dataSignature) { await recompute() }
    }

    private var dataSignature: String {
        "\(sessions.count)-\(sessions.first?.id.uuidString ?? "")"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            LoadingView(label: "Crunching your numbers…")
        } else if snapshots.isEmpty {
            EmptyStateView(symbol: "chart.xyaxis.line",
                           title: "No progress yet",
                           message: "Finish a few workouts and your strength trends, volume, and PRs will appear here.")
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid
                    if isPro {
                        e1rmCard
                        volumeByGroupCard
                        weeklyVolumeCard
                        prBoardCard
                    } else {
                        prBoardCard      // PRs are a free taste
                        proTeaser
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: Summary (free)

    private var summaryGrid: some View {
        let summary = StatsEngine.summary(sessions: snapshots)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Sessions", "\(summary.sessionCount)", "checkmark.circle")
            statCard("Total volume", compactKg(summary.totalVolumeKg), "scalemass")
            statCard("Week streak", "\(summary.currentStreakWeeks)", "flame")
            statCard("Lifts tracked", "\(summary.distinctLifts)", "dumbbell")
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(value)
                    .font(Theme.num(26, .heavy))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(title)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: e1RM (Pro)

    private var e1rmCard: some View {
        let series = StatsEngine.e1rmSeries(liftName: selectedLift, sessions: snapshots)
        return chartCard(title: "Estimated 1RM", symbol: "chart.xyaxis.line") {
            if liftNames.count > 1 {
                Picker("Lift", selection: $selectedLift) {
                    ForEach(liftNames, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            }
            if series.count < 2 {
                Text("Log this lift across more sessions to see a trend.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(series) { point in
                    LineMark(x: .value("Date", point.date),
                             y: .value("e1RM", Units.toDisplay(point.e1rmKg, unit: settings.unit)))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", point.date),
                              y: .value("e1RM", Units.toDisplay(point.e1rmKg, unit: settings.unit)))
                        .foregroundStyle(Theme.accent)
                }
                .chartYAxisLabel(settings.unit.label)
                .frame(height: 200)
                .accessibilityLabel("Estimated one rep max trend for \(selectedLift)")
            }
        }
    }

    // MARK: Volume by group (Pro)

    private var volumeByGroupCard: some View {
        let data = StatsEngine.volumeByGroup(sessions: snapshots)
        return chartCard(title: "Volume by muscle group", symbol: "chart.bar.fill") {
            if data.isEmpty {
                Text("No volume recorded yet.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Chart(data) { item in
                    BarMark(x: .value("Volume", Units.toDisplay(item.volumeKg, unit: settings.unit)),
                            y: .value("Group", item.group.label))
                        .foregroundStyle(item.group.hue)
                        .cornerRadius(5)
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(data.count) * 38 + 10)
                .accessibilityLabel("Training volume by muscle group")
            }
        }
    }

    // MARK: Weekly volume (Pro)

    private var weeklyVolumeCard: some View {
        let data = StatsEngine.weeklyVolume(sessions: snapshots)
        return chartCard(title: "Weekly volume", symbol: "calendar") {
            if data.isEmpty {
                Text("No weekly data yet.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Chart(data) { item in
                    BarMark(x: .value("Week", item.weekStart, unit: .weekOfYear),
                            y: .value("Volume", Units.toDisplay(item.volumeKg, unit: settings.unit)))
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(4)
                }
                .frame(height: 200)
                .accessibilityLabel("Total training volume per week")
            }
        }
    }

    // MARK: PR board (free taste + Pro)

    private var prBoardCard: some View {
        let prs = StatsEngine.personalRecords(sessions: snapshots)
        return chartCard(title: "Personal records", symbol: "trophy.fill") {
            if prs.isEmpty {
                Text("Your best estimated 1RMs will appear here.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                VStack(spacing: 10) {
                    ForEach(isPro ? prs : Array(prs.prefix(3))) { pr in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pr.liftName)
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Text(settings.weight(pr.bestE1RMKg))
                                .font(Theme.num(18, .heavy))
                                .foregroundStyle(Theme.accent)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(pr.liftName) best estimated one rep max \(settings.weight(pr.bestE1RMKg))")
                    }
                }
            }
        }
    }

    private var proTeaser: some View {
        Card(padding: 22) {
            VStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Unlock full analytics")
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.ink)
                Text("e1RM trends per lift, volume by muscle group, and weekly volume are part of Ascend Pro.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "See Ascend Pro", systemImage: "crown.fill") {
                    paywallReason = .analytics
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func chartCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: symbol)
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                content()
            }
        }
    }

    private func compactKg(_ kg: Double) -> String {
        let v = Units.toDisplay(kg, unit: settings.unit)
        if v >= 1000 {
            return String(format: "%.1fk", v / 1000) + " " + settings.unit.label
        }
        return Units.formatWeight(kg, unit: settings.unit)
    }

    // MARK: Compute

    @MainActor
    private func recompute() async {
        isLoading = true
        let snaps = StatsSnapshot.build(from: sessions)
        try? await Task.sleep(nanoseconds: 300_000_000)
        let names = StatsEngine.liftNames(sessions: snaps)
        snapshots = snaps
        liftNames = names
        if selectedLift.isEmpty || !names.contains(selectedLift) {
            selectedLift = names.first ?? ""
        }
        isLoading = false
    }
}
