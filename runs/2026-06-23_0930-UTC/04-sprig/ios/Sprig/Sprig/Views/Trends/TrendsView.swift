import SwiftUI
import SwiftData
import Charts

/// Real Swift Charts for feeds/day, sleep hours/day, and diaper trend, with a
/// selectable window and at-a-glance averages.
struct TrendsView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true

    @Bindable var baby: Baby

    @State private var window: Window = .twoWeeks
    @State private var isLoading = true
    @State private var series: [DaySummary] = []

    enum Window: Int, CaseIterable, Identifiable {
        case week = 7, twoWeeks = 14, month = 30
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .week: return "7 days"
            case .twoWeeks: return "14 days"
            case .month: return "30 days"
            }
        }
    }

    private var hasData: Bool {
        series.contains { $0.feedCount > 0 || $0.sleepSeconds > 0 || $0.diaperCount > 0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientGradient(scheme).ignoresSafeArea()
                if isLoading {
                    ProgressView("Crunching the numbers…")
                        .tint(Theme.accent)
                        .foregroundStyle(Theme.secondaryText(scheme))
                } else if !hasData {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "No trends yet",
                        message: "Once you've logged a few days of feeds, sleep and diapers, your charts will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            picker
                            averages
                            feedsChart
                            sleepChart
                            diaperChart
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Trends")
            .task(id: window) { await load() }
        }
    }

    private func load() async {
        isLoading = true
        // Yield so the spinner can show for computed work on large datasets.
        await Task.yield()
        let computed = SprigEngine.dailySeries(for: baby, days: window.rawValue)
        await MainActor.run {
            series = computed
            isLoading = false
        }
    }

    private var picker: some View {
        Picker("Window", selection: $window) {
            ForEach(Window.allCases) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
        .onChange(of: window) { _, _ in Haptics.selection(haptics) }
    }

    private var averages: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            StatTile(icon: "drop.fill",
                     value: Fmt.num(SprigEngine.avgFeedsPerDay(series)),
                     label: "Feeds/day", tint: Theme.apricot)
            StatTile(icon: "moon.fill",
                     value: "\(Fmt.num(SprigEngine.avgSleepHours(series)))h",
                     label: "Sleep/day", tint: Theme.sky)
            StatTile(icon: "circle.grid.cross.fill",
                     value: Fmt.num(SprigEngine.avgDiapersPerDay(series)),
                     label: "Diapers/day", tint: Theme.clay)
        }
    }

    private var feedsChart: some View {
        chartCard(title: "Feeds per day", systemImage: "drop.fill", tint: Theme.apricot) {
            Chart(series) { day in
                BarMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Feeds", day.feedCount)
                )
                .foregroundStyle(Theme.apricot.gradient)
                .cornerRadius(4)
            }
            .chartYAxisLabel("count")
            .frame(height: 180)
            .chartXAxis { xAxis }
        }
    }

    private var sleepChart: some View {
        chartCard(title: "Sleep hours per day", systemImage: "moon.fill", tint: Theme.sky) {
            Chart(series) { day in
                LineMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Hours", day.sleepHours)
                )
                .foregroundStyle(Theme.sky)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Hours", day.sleepHours)
                )
                .foregroundStyle(Theme.sky.opacity(0.15).gradient)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Hours", day.sleepHours)
                )
                .foregroundStyle(Theme.sky)
                .symbolSize(28)
            }
            .chartYAxisLabel("hours")
            .frame(height: 180)
            .chartXAxis { xAxis }
        }
    }

    private var diaperChart: some View {
        chartCard(title: "Diaper trend", systemImage: "circle.grid.cross.fill", tint: Theme.clay) {
            Chart(series) { day in
                BarMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Wet", day.wetCount)
                )
                .foregroundStyle(Theme.sky)
                .position(by: .value("Kind", "Wet"))
                BarMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Dirty", day.dirtyCount)
                )
                .foregroundStyle(Theme.clay)
                .position(by: .value("Kind", "Dirty"))
            }
            .chartForegroundStyleScale(["Wet": Theme.sky, "Dirty": Theme.clay])
            .chartYAxisLabel("count")
            .frame(height: 180)
            .chartXAxis { xAxis }
        }
    }

    private var xAxis: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: max(1, window.rawValue / 7))) { value in
            AxisGridLine()
            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
        }
    }

    @ViewBuilder
    private func chartCard<Content: View>(title: String, systemImage: String, tint: Color,
                                          @ViewBuilder content: () -> Content) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title, systemImage: systemImage)
                content()
                    .accessibilityLabel(title)
            }
        }
    }
}
