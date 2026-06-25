import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \SurfSession.date, order: .forward) private var sessions: [SurfSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            summaryRow
                            sessionsPerMonthChart
                            conditionsDonut
                            ratingTrendChart
                            topSpotsChart
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Summary Row
    private var summaryRow: some View {
        HStack(spacing: 12) {
            SummaryTile(value: "\(sessions.count)", label: "Total Sessions", icon: "water.waves")
            SummaryTile(value: "\(totalHours)h", label: "Total Time", icon: "clock.fill")
            SummaryTile(value: String(format: "%.1f", avgRating), label: "Avg Rating", icon: "star.fill")
        }
    }

    // MARK: - Sessions per Month
    private var sessionsPerMonthChart: some View {
        ChartCard(title: "Sessions per Month") {
            Chart(monthlyData) { item in
                BarMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Sessions", item.count)
                )
                .foregroundStyle(SwellTheme.teal)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 160)
        }
    }

    // MARK: - Conditions Donut
    private var conditionsDonut: some View {
        ChartCard(title: "Session Conditions") {
            HStack(alignment: .top, spacing: 16) {
                Chart(conditionsData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.conditions.color)
                    .cornerRadius(4)
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(conditionsData) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.conditions.color)
                                .frame(width: 10, height: 10)
                                .accessibilityHidden(true)
                            Text(item.conditions.rawValue)
                                .font(.caption)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Rating Trend
    private var ratingTrendChart: some View {
        ChartCard(title: "Rating Trend") {
            Chart(monthlyRatingData) { item in
                LineMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Avg Rating", item.avgRating)
                )
                .foregroundStyle(SwellTheme.coral)
                .interpolationMethod(.monotone)
                PointMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Avg Rating", item.avgRating)
                )
                .foregroundStyle(SwellTheme.coral)
            }
            .chartYScale(domain: 1...5)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 140)
        }
    }

    // MARK: - Top Spots
    private var topSpotsChart: some View {
        ChartCard(title: "Top Spots") {
            Chart(topSpots) { item in
                BarMark(
                    x: .value("Sessions", item.count),
                    y: .value("Spot", item.name)
                )
                .foregroundStyle(SwellTheme.teal)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { _ in AxisValueLabel() }
            }
            .frame(height: CGFloat(max(80, topSpots.count * 40)))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundStyle(SwellTheme.teal.opacity(0.5))
                .accessibilityHidden(true)
            Text("No data yet")
                .font(.title3.bold())
            Text("Log your first sessions to see your surf stats here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No stats available. Log sessions to see your data.")
    }

    // MARK: - Computed Data

    private var totalHours: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes } / 60
    }

    private var avgRating: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.rating }) / Double(sessions.count)
    }

    private struct MonthData: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    private struct MonthRating: Identifiable {
        let id = UUID()
        let date: Date
        let avgRating: Double
    }

    private struct ConditionsData: Identifiable {
        let id = UUID()
        let conditions: SessionConditions
        let count: Int
    }

    private struct SpotData: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }

    private var monthlyData: [MonthData] {
        let cal = Calendar.current
        var counts: [Date: Int] = [:]
        for s in sessions {
            let start = cal.startOfMonth(for: s.date)
            counts[start, default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }.map { MonthData(date: $0.key, count: $0.value) }
    }

    private var monthlyRatingData: [MonthRating] {
        let cal = Calendar.current
        var sums: [Date: (Int, Int)] = [:]
        for s in sessions {
            let start = cal.startOfMonth(for: s.date)
            let existing = sums[start] ?? (0, 0)
            sums[start] = (existing.0 + s.rating, existing.1 + 1)
        }
        return sums.sorted { $0.key < $1.key }.map { (date, pair) in
            MonthRating(date: date, avgRating: pair.1 > 0 ? Double(pair.0) / Double(pair.1) : 0)
        }
    }

    private var conditionsData: [ConditionsData] {
        var counts: [SessionConditions: Int] = [:]
        for s in sessions { counts[s.conditions, default: 0] += 1 }
        return SessionConditions.allCases.compactMap { c in
            guard let count = counts[c], count > 0 else { return nil }
            return ConditionsData(conditions: c, count: count)
        }
    }

    private var topSpots: [SpotData] {
        var counts: [String: Int] = [:]
        for s in sessions where !s.spotName.isEmpty {
            counts[s.spotName, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(6).map { SpotData(name: $0.key, count: $0.value) }
    }
}

struct SummaryTile: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(SwellTheme.teal)
                .accessibilityHidden(true)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
