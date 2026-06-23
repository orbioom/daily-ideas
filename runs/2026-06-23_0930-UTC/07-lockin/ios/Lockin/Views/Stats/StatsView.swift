import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

    enum Range: String, CaseIterable, Identifiable {
        case week = "7 days"
        case month = "30 days"
        case all = "All"
        var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return 365
            }
        }
    }

    @State private var range: Range = .week
    @State private var computed: Computed?
    @State private var isLoading = false

    /// Pre-aggregated values to keep chart bodies cheap.
    struct Computed {
        var summary: FocusAnalytics.Summary
        var daily: [FocusAnalytics.DayBucket]
        var byProject: [FocusAnalytics.ProjectBucket]
        var byHour: [FocusAnalytics.HourBucket]
        var currentStreak: Int
        var longestStreak: Int
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.appBackground.ignoresSafeArea()
                if sessions.isEmpty {
                    EmptyStateView(systemImage: "chart.bar.xaxis",
                                   title: "No data yet",
                                   message: "Complete a few focus sessions and your analytics will build up here.")
                } else if isLoading || computed == nil {
                    ProgressView("Crunching your focus…")
                        .tint(Theme.Palette.brand)
                        .foregroundStyle(Theme.Palette.textSecondary)
                } else if let c = computed {
                    content(c)
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Range", selection: $range) {
                        ForEach(Range.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Palette.brand)
                }
            }
        }
        .task(id: rangeAndCount) { await recompute() }
    }

    /// Recompute whenever the range or session count changes.
    private var rangeAndCount: String { "\(range.rawValue)-\(sessions.count)" }

    @MainActor
    private func recompute() async {
        isLoading = true
        // Snapshot needed values off the model objects before the async hop.
        let windowed = FocusAnalytics.within(sessions, days: range.days)
        let result = Computed(
            summary: FocusAnalytics.summary(windowed),
            daily: FocusAnalytics.dailyMinutes(windowed, days: min(range.days, 30)),
            byProject: FocusAnalytics.byProject(windowed),
            byHour: FocusAnalytics.byHour(windowed),
            currentStreak: FocusAnalytics.currentStreak(sessions),
            longestStreak: FocusAnalytics.longestStreak(sessions)
        )
        // Tiny yield so the loading state is observable and the UI stays smooth.
        try? await Task.sleep(nanoseconds: 120_000_000)
        computed = result
        isLoading = false
    }

    private func content(_ c: Computed) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                summaryGrid(c)
                streakCard(c)
                dailyChart(c)
                projectChart(c)
                hourHeatmap(c)
                distractionCard(c)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func summaryGrid(_ c: Computed) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
            StatTile(title: "Focus time", value: TimeFormat.duration(minutes: c.summary.totalMinutes),
                     systemImage: "clock.fill", tint: Theme.Palette.warm)
            StatTile(title: "Sessions", value: "\(c.summary.completedSessions)",
                     systemImage: "checkmark.circle.fill", tint: Theme.Palette.success)
            StatTile(title: "Avg session", value: "\(c.summary.avgSessionMinutes)m",
                     systemImage: "gauge.medium", tint: Theme.Palette.brand)
            StatTile(title: "Completion", value: "\(Int(c.summary.completionRate * 100))%",
                     systemImage: "target", tint: Theme.Palette.brand)
        }
    }

    private func streakCard(_ c: Computed) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            streakItem(value: c.currentStreak, label: "Current streak", symbol: "flame.fill", tint: Theme.Palette.warm)
            Divider().frame(height: 44)
            streakItem(value: c.longestStreak, label: "Longest streak", symbol: "trophy.fill", tint: Theme.Palette.brand)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .cardSurface()
    }

    private func streakItem(value: Int, label: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: symbol).foregroundStyle(tint)
                Text("\(value)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
            Text("\(label) · \(value == 1 ? "day" : "days")")
                .font(.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) days")
    }

    private func dailyChart(_ c: Computed) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Focus minutes per day")
            if c.summary.totalMinutes == 0 {
                inlineEmpty
            } else {
                Chart(c.daily) { bucket in
                    BarMark(
                        x: .value("Day", bucket.date, unit: .day),
                        y: .value("Minutes", bucket.minutes)
                    )
                    .foregroundStyle(Theme.Palette.brand.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, c.daily.count / 6))) { value in
                        AxisValueLabel(format: .dateTime.day().month(.narrow))
                    }
                }
                .frame(height: 200)
                .accessibilityLabel("Bar chart of focus minutes per day")
            }
        }
        .padding(Theme.Spacing.lg)
        .cardSurface()
    }

    private func projectChart(_ c: Computed) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Time by project")
            if c.byProject.isEmpty {
                inlineEmpty
            } else {
                Chart(c.byProject) { bucket in
                    BarMark(
                        x: .value("Minutes", bucket.minutes),
                        y: .value("Project", bucket.name)
                    )
                    .foregroundStyle(Color(hex: bucket.colorHex) ?? Theme.Palette.brand)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(TimeFormat.duration(minutes: bucket.minutes))
                            .font(.caption2)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                }
                .frame(height: CGFloat(max(120, c.byProject.count * 44)))
                .accessibilityLabel("Bar chart of focus time by project")
            }
        }
        .padding(Theme.Spacing.lg)
        .cardSurface()
    }

    private func hourHeatmap(_ c: Computed) -> some View {
        let maxMin = max(1, c.byHour.map(\.minutes).max() ?? 1)
        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "When you focus")
            Text("Total minutes by hour of day")
                .font(.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
            if c.summary.totalMinutes == 0 {
                inlineEmpty
            } else {
                Chart(c.byHour) { bucket in
                    RectangleMark(
                        x: .value("Hour", bucket.hour),
                        y: .value("Focus", "Focus")
                    )
                    .foregroundStyle(Theme.Palette.brand.opacity(0.15 + 0.85 * Double(bucket.minutes) / Double(maxMin)))
                }
                .chartXScale(domain: 0...23)
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                        if let h = value.as(Int.self) {
                            AxisValueLabel { Text(TimeFormat.hourLabel(h)) }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 70)
                .accessibilityLabel("Heatmap of focus minutes by hour of day")
                .accessibilityValue(peakHourText(c))
            }
        }
        .padding(Theme.Spacing.lg)
        .cardSurface()
    }

    private func peakHourText(_ c: Computed) -> String {
        guard let peak = c.byHour.max(by: { $0.minutes < $1.minutes }), peak.minutes > 0 else {
            return "No peak hour yet"
        }
        return "Peak focus hour around \(TimeFormat.hourLabel(peak.hour))"
    }

    private func distractionCard(_ c: Computed) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Distractions logged")
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Text("\(c.summary.totalDistractions)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(distractionInsight(c))
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.largeTitle)
                .foregroundStyle(Theme.Palette.warm)
                .accessibilityHidden(true)
        }
        .padding(Theme.Spacing.lg)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private func distractionInsight(_ c: Computed) -> String {
        let total = c.summary.completedSessions + c.summary.abandonedSessions
        guard total > 0 else { return "Start a session to track distractions." }
        let avg = Double(c.summary.totalDistractions) / Double(total)
        return String(format: "About %.1f per session", avg)
    }

    private var inlineEmpty: some View {
        Text("No focus logged in this range yet.")
            .font(.subheadline)
            .foregroundStyle(Theme.Palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Theme.Spacing.lg)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [Project.self, FocusSession.self, AppSettings.self], inMemory: true)
}
