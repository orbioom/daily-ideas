import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @State private var range: Range = .month
    @State private var showPaywall = false

    enum Range: String, CaseIterable, Identifiable {
        case week = "7d", month = "30d", quarter = "90d"
        var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }

    private var activeDog: Dog? { DogManager.activeDog(from: dogs) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Group {
                    if let dog = activeDog {
                        if dog.sessions.isEmpty {
                            EmptyStateView(
                                systemImage: "chart.bar.xaxis",
                                title: "No data yet",
                                message: "Complete a few training sessions and your stats will come to life here."
                            )
                        } else {
                            content(for: dog)
                        }
                    } else {
                        EmptyStateView(
                            systemImage: "chart.bar.xaxis",
                            title: "No dog selected",
                            message: "Add a dog to see training insights."
                        )
                    }
                }
            }
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func content(for dog: Dog) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                summaryGrid(for: dog)

                rangePicker

                sessionsChart(for: dog)
                minutesChart(for: dog)

                if isPro {
                    categoryChart(for: dog)
                    ratingsChart(for: dog)
                } else {
                    proTeaser
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }

    private func summaryGrid(for dog: Dog) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 12) {
            SummaryTile(value: "\(StatsEngine.totalSessions(for: dog))", label: "Sessions", icon: "timer", color: Theme.accent)
            SummaryTile(value: "\(StatsEngine.totalMinutes(for: dog))", label: "Minutes", icon: "clock.fill", color: Theme.good)
            SummaryTile(value: "\(ProgressEngine.masteredCount(for: dog))", label: "Mastered", icon: "checkmark.seal.fill", color: Theme.warn)
            SummaryTile(value: "\(ProgressEngine.trainingStreak(for: dog))", label: "Day streak", icon: "flame.fill", color: Theme.bad)
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            ForEach(Range.allCases) { r in Text(r.rawValue).tag(r) }
        }
        .pickerStyle(.segmented)
    }

    private func sessionsChart(for dog: Dog) -> some View {
        let data = StatsEngine.daily(for: dog, days: range.days)
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Sessions over time", systemImage: "calendar")
                Chart(data) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Sessions", point.sessions)
                    )
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(3)
                    .accessibilityLabel(Format.shortDate(point.date))
                    .accessibilityValue("\(point.sessions) sessions")
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 170)
            }
        }
    }

    private func minutesChart(for dog: Dog) -> some View {
        let data = StatsEngine.daily(for: dog, days: range.days)
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Minutes trained", systemImage: "clock.fill")
                Chart(data) { point in
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Minutes", point.minutes)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.18))
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Minutes", point.minutes)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.monotone)
                    .accessibilityLabel(Format.shortDate(point.date))
                    .accessibilityValue("\(point.minutes) minutes")
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 170)
            }
        }
    }

    private func categoryChart(for dog: Dog) -> some View {
        let data = StatsEngine.byCategory(for: dog)
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Mastery by category", systemImage: "square.grid.2x2.fill")
                Chart(data) { point in
                    BarMark(
                        x: .value("Mastered", point.mastered),
                        y: .value("Category", point.category.rawValue)
                    )
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(point.mastered)/\(point.total)")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityLabel(point.category.rawValue)
                    .accessibilityValue("\(point.mastered) of \(point.total) mastered")
                }
                .frame(height: 200)
            }
        }
    }

    private func ratingsChart(for dog: Dog) -> some View {
        let data = StatsEngine.ratings(for: dog)
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Session ratings", systemImage: "star.fill")
                Chart(data) { point in
                    BarMark(
                        x: .value("Rating", "\(point.rating)\u{2605}"),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(Theme.warn)
                    .cornerRadius(4)
                    .accessibilityLabel("\(point.rating) stars")
                    .accessibilityValue("\(point.count) sessions")
                }
                .frame(height: 160)
            }
        }
    }

    private var proTeaser: some View {
        Button { showPaywall = true } label: {
            Card {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Text("Unlock advanced stats")
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("See mastery by category and your session-rating distribution with Fetch Pro.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                    Chip(text: "Unlock Pro", systemImage: "lock.open.fill", color: Theme.warn)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SummaryTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var body: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
                Text(value)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text(label)
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}
