import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \CookLog.date, order: .reverse) private var logs: [CookLog]
    @Environment(\.modelContext) private var context

    @State private var showSettings = false
    @State private var toast: ToastMessage? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if logs.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "No cooks logged yet",
                        message: "Start a timer from a food and it'll appear here, building your cooking history and stats."
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Cook Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .toast($toast)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                statTiles
                weeklyChart
                topFoodsChart
                recentList
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    // MARK: Summary tiles

    private var statTiles: some View {
        HStack(spacing: 12) {
            statTile(value: "\(logs.count)", label: "Total cooks", icon: "flame.fill")
            statTile(value: avgRatingText, label: "Avg rating", icon: "star.fill")
            statTile(value: "\(distinctFoodCount)", label: "Foods tried", icon: "fork.knife")
        }
    }

    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(label)
                .font(Theme.roundedStyle(.caption))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .crispCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var avgRatingText: String {
        let rated = logs.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return "—" }
        let total = rated.reduce(0) { $0 + $1.rating }
        let avg = Double(total) / Double(rated.count)
        return String(format: "%.1f", avg)
    }

    private var distinctFoodCount: Int {
        Set(logs.map { $0.foodId ?? $0.name }).count
    }

    // MARK: Weekly chart

    private struct DayCount: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    private var last14Days: [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var buckets: [Date: Int] = [:]
        for log in logs {
            let day = cal.startOfDay(for: log.date)
            if let diff = cal.dateComponents([.day], from: day, to: today).day, diff >= 0, diff < 14 {
                buckets[day, default: 0] += 1
            }
        }
        var result: [DayCount] = []
        for offset in stride(from: 13, through: 0, by: -1) {
            if let day = cal.date(byAdding: .day, value: -offset, to: today) {
                result.append(DayCount(date: day, count: buckets[day] ?? 0))
            }
        }
        return result
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cooks per day", subtitle: "Last 14 days")
            Chart(last14Days) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Cooks", item.count)
                )
                .foregroundStyle(Theme.heroGradient)
                .cornerRadius(4)
                .accessibilityLabel(item.date.formatted(.dateTime.month().day()))
                .accessibilityValue("\(item.count) cooks")
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(16)
        .crispCard()
    }

    // MARK: Top foods chart

    private struct FoodCount: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }

    private var topFoods: [FoodCount] {
        var counts: [String: Int] = [:]
        for log in logs { counts[log.name, default: 0] += 1 }
        let sorted = counts.sorted { lhs, rhs in
            lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key < rhs.key
        }
        return sorted.prefix(6).map { FoodCount(name: $0.key, count: $0.value) }
    }

    private var topFoodsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Most cooked", subtitle: "Your go-to foods")
            Chart(topFoods) { item in
                BarMark(
                    x: .value("Cooks", item.count),
                    y: .value("Food", item.name)
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(Theme.roundedStyle(.caption, .bold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .accessibilityLabel(item.name)
                .accessibilityValue("\(item.count) cooks")
            }
            .frame(height: max(120, CGFloat(topFoods.count) * 38))
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
        }
        .padding(16)
        .crispCard()
    }

    // MARK: Recent list

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent cooks")
            ForEach(logs.prefix(12)) { log in
                HStack(spacing: 12) {
                    Text(iconFor(log))
                        .font(.system(size: 26))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.name)
                            .font(Theme.roundedStyle(.subheadline, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(Fmt.temp(fahrenheit: log.tempF, unit: settings.tempUnit)) · \(Fmt.minutesLabel(log.minutes)) · \(log.date.formatted(.dateTime.month().day()))")
                            .font(Theme.roundedStyle(.caption))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    if log.rating > 0 {
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= log.rating ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundStyle(star <= log.rating ? Theme.accent : Theme.hairline)
                            }
                        }
                        .accessibilityLabel("\(log.rating) of 5 stars")
                    }
                }
                .padding(14)
                .crispCard(radius: Theme.chipRadius)
                .contextMenu {
                    Button(role: .destructive) { delete(log) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func iconFor(_ log: CookLog) -> String {
        if let id = log.foodId, let food = FoodCatalog.byId[id] { return food.icon }
        return "🍽️"
    }

    private func delete(_ log: CookLog) {
        context.delete(log)
        try? context.save()
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
        toast = ToastMessage(symbol: "trash", text: "Removed from log")
    }
}
