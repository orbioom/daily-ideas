import SwiftUI
import SwiftData
import Charts

struct PaceStatsView: View {
    @Query(sort: \RunSession.date, order: .reverse) private var sessions: [RunSession]
    @AppStorage("pace_use_km") private var useKm = true

    private var stats: RunStatsResult {
        PaceStats.compute(from: sessions)
    }

    private var weeklyData: [(Date, Double)] {
        PaceStats.weeklyDistances(from: sessions, weeks: 8)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // This week summary
                    ThisWeekCard(stats: stats, useKm: useKm)
                        .padding(.horizontal)

                    // Weekly distance chart
                    WeeklyChartCard(weeklyData: weeklyData, useKm: useKm)
                        .padding(.horizontal)

                    // Personal records
                    PersonalRecordsCard(stats: stats, sessions: sessions, useKm: useKm)
                        .padding(.horizontal)

                    // Lifetime totals
                    LifetimeTotalsCard(stats: stats, useKm: useKm)
                        .padding(.horizontal)

                    // Streak
                    StreakCard(streak: stats.currentStreak)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
                .padding(.top)
            }
            .navigationTitle("Stats")
        }
    }
}

private struct ThisWeekCard: View {
    let stats: RunStatsResult
    let useKm: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(useKm
                         ? String(format: "%.1f", stats.weeklyDistanceKm)
                         : String(format: "%.1f", stats.weeklyDistanceKm * 0.621371))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(PaceTheme.accent)
                    Text(useKm ? "km" : "miles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider().frame(height: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text(PaceStats.formatDuration(stats.totalDurationSeconds))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("total time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct WeeklyChartCard: View {
    let weeklyData: [(Date, Double)]
    let useKm: Bool

    private var chartData: [(label: String, distance: Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return weeklyData.map { (date, dist) in
            (formatter.string(from: date), useKm ? dist : dist * 0.621371)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("8-Week Distance")
                .font(.headline)
                .foregroundStyle(.secondary)

            Chart(chartData, id: \.label) { item in
                BarMark(
                    x: .value("Week", item.label),
                    y: .value(useKm ? "km" : "mi", item.distance)
                )
                .foregroundStyle(PaceTheme.accent.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PersonalRecordsCard: View {
    let stats: RunStatsResult
    let sessions: [RunSession]
    let useKm: Bool

    private var mostInOneDay: Double {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
        return grouped.values.map { $0.reduce(0) { $0 + $1.distanceKm } }.max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Records")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                PRRow(
                    icon: "trophy.fill",
                    color: .yellow,
                    title: "Longest Run",
                    value: useKm
                        ? String(format: "%.2f km", stats.longestRunKm)
                        : String(format: "%.2f mi", stats.longestRunKm * 0.621371)
                )
                Divider()
                PRRow(
                    icon: "bolt.fill",
                    color: .orange,
                    title: "Best Pace",
                    value: stats.bestPaceSecondsPerKm > 0
                        ? "\(PaceStats.formatPace(stats.bestPaceSecondsPerKm))/km"
                        : "--"
                )
                Divider()
                PRRow(
                    icon: "calendar",
                    color: .blue,
                    title: "Most in One Day",
                    value: useKm
                        ? String(format: "%.2f km", mostInOneDay)
                        : String(format: "%.2f mi", mostInOneDay * 0.621371)
                )
            }
        }
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PRRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

private struct LifetimeTotalsCard: View {
    let stats: RunStatsResult
    let useKm: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lifetime Totals")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCell(
                    title: "Total Activities",
                    value: "\(stats.totalRuns)"
                )
                StatCell(
                    title: useKm ? "Total Distance" : "Total Distance",
                    value: useKm
                        ? String(format: "%.1f km", stats.totalDistanceKm)
                        : String(format: "%.1f mi", stats.totalDistanceKm * 0.621371)
                )
                StatCell(
                    title: "Total Time",
                    value: PaceStats.formatDuration(stats.totalDurationSeconds)
                )
                StatCell(
                    title: "Avg Pace",
                    value: stats.averagePaceSecondsPerKm > 0
                        ? "\(PaceStats.formatPace(stats.averagePaceSecondsPerKm))/km"
                        : "--"
                )
            }
        }
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StreakCard: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(streak)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(streak == 0 ? "Run today to start a streak!" : "Keep it up!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
