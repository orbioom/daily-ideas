import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \SwimSession.date, order: .reverse) private var sessions: [SwimSession]
    @Query private var settingsAll: [SplashSettings]

    var useYards: Bool { settingsAll.first?.useYards ?? false }
    var weeklyGoalKm: Double { settingsAll.first?.weeklyGoalKm ?? 3.0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    ContentUnavailableView {
                        Label("No Data Yet", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text("Log swim sessions to see stats and charts.")
                    }
                } else {
                    VStack(spacing: 20) {
                        SummaryStatsSection(sessions: sessions, useYards: useYards)
                        WeeklyDistanceChart(sessions: sessions, useYards: useYards, goalKm: weeklyGoalKm)
                        StrokeDistributionChart(sessions: sessions)
                        PaceTrendChart(sessions: sessions, useYards: useYards)
                        SessionsPerMonthChart(sessions: sessions)
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
        }
    }
}

private struct SummaryStatsSection: View {
    let sessions: [SwimSession]
    let useYards: Bool

    var totalDistance: Double {
        sessions.reduce(0) { $0 + ($1.computedDistance > 0 ? $1.computedDistance : $1.totalDistanceMeters) }
    }

    var totalDuration: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    var avgRating: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.feelRating }) / Double(sessions.count)
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Total Distance",
                value: metersToDisplay(totalDistance, useYards: useYards),
                subtitle: "\(sessions.count) sessions",
                icon: "arrow.left.and.right",
                color: SplashTheme.accent
            )
            StatCard(
                title: "Total Time",
                value: formatDuration(totalDuration),
                subtitle: "\(totalDuration / 3600)h in the water",
                icon: "clock.fill",
                color: Color(red: 0.28, green: 0.52, blue: 0.93)
            )
            StatCard(
                title: "Avg Distance",
                value: metersToDisplay(sessions.isEmpty ? 0 : totalDistance / Double(sessions.count), useYards: useYards),
                subtitle: "per session",
                icon: "chart.bar.fill",
                color: Color(red: 0.20, green: 0.80, blue: 0.60)
            )
            StatCard(
                title: "Avg Feel",
                value: String(format: "%.1f★", avgRating),
                subtitle: "out of 5",
                icon: "star.fill",
                color: .yellow
            )
        }
    }
}

private struct WeeklyDistanceChart: View {
    let sessions: [SwimSession]
    let useYards: Bool
    let goalKm: Double

    struct WeekPoint: Identifiable {
        let id = UUID()
        let weekLabel: String
        let distanceKm: Double
        let weekStart: Date
    }

    var weeklyData: [WeekPoint] {
        let cal = Calendar.current
        let now = Date()
        var points: [WeekPoint] = []
        for w in (0..<12).reversed() {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -w, to: now).flatMap({ cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: $0)) }),
                  let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            let dist = sessions
                .filter { $0.date >= weekStart && $0.date < weekEnd }
                .reduce(0.0) { $0 + ($1.computedDistance > 0 ? $1.computedDistance : $1.totalDistanceMeters) }
            let fmt = DateFormatter()
            fmt.dateFormat = "M/d"
            points.append(WeekPoint(weekLabel: fmt.string(from: weekStart), distanceKm: dist / 1000, weekStart: weekStart))
        }
        return points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Distance (km)")
                .font(.headline)
            Chart {
                ForEach(weeklyData) { p in
                    BarMark(
                        x: .value("Week", p.weekLabel),
                        y: .value("km", p.distanceKm)
                    )
                    .foregroundStyle(SplashTheme.accent.gradient)
                    .cornerRadius(4)
                }
                RuleMark(y: .value("Goal", goalKm))
                    .foregroundStyle(.orange.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal \(goalKm, specifier: "%.1f")km")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { val in
                    AxisValueLabel { if let s = val.as(String.self) { Text(s).font(.caption2) } }
                }
            }
        }
        .padding()
        .background(SplashTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct StrokeDistributionChart: View {
    let sessions: [SwimSession]

    struct StrokeSlice: Identifiable {
        let id = UUID()
        let stroke: String
        let distanceKm: Double
    }

    var data: [StrokeSlice] {
        var map: [String: Double] = [:]
        for session in sessions {
            for set in session.sets {
                map[set.strokeType, default: 0] += set.totalDistanceMeters / 1000
            }
        }
        return map.map { StrokeSlice(stroke: $0.key, distanceKm: $0.value) }
            .sorted { $0.distanceKm > $1.distanceKm }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stroke Distribution")
                .font(.headline)
            Chart(data) { slice in
                SectorMark(
                    angle: .value("Distance", slice.distanceKm),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(SplashTheme.strokeColor(slice.stroke))
                .cornerRadius(4)
                .annotation(position: .overlay) {
                    let total = data.reduce(0.0) { $0 + $1.distanceKm }
                    if total > 0 && (slice.distanceKm / total) > 0.08 {
                        Text(slice.stroke.strokeDisplayName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 200)
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(data) { slice in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(SplashTheme.strokeColor(slice.stroke))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(slice.stroke.strokeDisplayName)
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.1fkm", slice.distanceKm))
                            .font(.caption.bold())
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(slice.stroke.strokeDisplayName): \(String(format: "%.1f", slice.distanceKm)) km")
                }
            }
        }
        .padding()
        .background(SplashTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct PaceTrendChart: View {
    let sessions: [SwimSession]
    let useYards: Bool

    struct PacePoint: Identifiable {
        let id = UUID()
        let date: Date
        let pace: Double // seconds per 100m
    }

    var data: [PacePoint] {
        sessions
            .compactMap { s -> PacePoint? in
                let dist = s.computedDistance > 0 ? s.computedDistance : s.totalDistanceMeters
                guard dist > 0 && s.durationSeconds > 0 else { return nil }
                let pace = (Double(s.durationSeconds) / dist) * 100
                return PacePoint(date: s.date, pace: pace)
            }
            .sorted { $0.date < $1.date }
            .suffix(20)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pace Trend (sec / 100m)")
                .font(.headline)
            if data.isEmpty {
                Text("Add session duration to see pace trend")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 120)
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Pace", point.pace)
                    )
                    .foregroundStyle(Color(red: 0.28, green: 0.52, blue: 0.93))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Pace", point.pace)
                    )
                    .foregroundStyle(Color(red: 0.28, green: 0.52, blue: 0.93))
                    .symbolSize(40)
                }
                .frame(height: 140)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { val in
                        AxisValueLabel {
                            if let d = val.as(Date.self) {
                                Text(d, format: .dateTime.month(.abbreviated).day())
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { val in
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                let mins = Int(v) / 60
                                let secs = Int(v) % 60
                                Text(String(format: "%d:%02d", mins, secs))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
        }
        .padding()
        .background(SplashTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct SessionsPerMonthChart: View {
    let sessions: [SwimSession]

    struct MonthBar: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
    }

    var data: [MonthBar] {
        let cal = Calendar.current
        let now = Date()
        var result: [MonthBar] = []
        for m in (0..<6).reversed() {
            guard let monthDate = cal.date(byAdding: .month, value: -m, to: now),
                  let range = cal.dateInterval(of: .month, for: monthDate) else { continue }
            let count = sessions.filter { $0.date >= range.start && $0.date < range.end }.count
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM"
            result.append(MonthBar(label: fmt.string(from: monthDate), count: count))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sessions per Month")
                .font(.headline)
            Chart(data) { bar in
                BarMark(
                    x: .value("Month", bar.label),
                    y: .value("Sessions", bar.count)
                )
                .foregroundStyle(Color(red: 0.20, green: 0.80, blue: 0.60).gradient)
                .cornerRadius(4)
            }
            .frame(height: 140)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { val in
                    AxisValueLabel { if let v = val.as(Int.self) { Text("\(v)").font(.caption2) } }
                    AxisGridLine()
                }
            }
        }
        .padding()
        .background(SplashTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
