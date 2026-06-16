import SwiftUI
import Charts

/// Accuracy over recent sessions (line).
struct AccuracyChartCard: View {
    let sessions: [Session]

    var body: some View {
        let points = ProgressEngine.sessionPoints(sessions: sessions)
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Accuracy over time")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                if points.count < 2 {
                    chartEmpty
                } else {
                    Chart(points) { p in
                        LineMark(x: .value("Date", p.date),
                                 y: .value("Accuracy", p.accuracy * 100))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.good)
                        PointMark(x: .value("Date", p.date),
                                  y: .value("Accuracy", p.accuracy * 100))
                            .foregroundStyle(Theme.good)
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis { AxisMarks(values: [0, 50, 100]) }
                    .frame(height: 160)
                    .accessibilityLabel("Accuracy over the last \(points.count) rounds")
                    .accessibilityValue(accessibilitySummary(points))
                }
            }
        }
    }

    private func accessibilitySummary(_ points: [ProgressEngine.SessionPoint]) -> String {
        guard let first = points.first, let last = points.last else { return "No data" }
        return "From \(Int(first.accuracy * 100)) percent to \(Int(last.accuracy * 100)) percent."
    }

    private var chartEmpty: some View {
        Text("Finish a few more rounds to see a trend.")
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}

/// Average answer speed (seconds per question) over recent sessions (line; lower is better).
struct SpeedChartCard: View {
    let sessions: [Session]

    var body: some View {
        let points = ProgressEngine.sessionPoints(sessions: sessions)
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Speed over time")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Seconds per question — lower is faster")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                if points.count < 2 {
                    Text("Finish a few more rounds to see a trend.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart(points) { p in
                        LineMark(x: .value("Date", p.date),
                                 y: .value("Seconds", p.avgSecPerQuestion))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.opAdd)
                        AreaMark(x: .value("Date", p.date),
                                 y: .value("Seconds", p.avgSecPerQuestion))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.opAdd.opacity(0.12))
                    }
                    .frame(height: 160)
                    .accessibilityLabel("Average answer speed over the last \(points.count) rounds")
                }
            }
        }
    }
}

/// Cumulative stars earned over time (facts-mastered proxy).
struct StarsChartCard: View {
    let sessions: [Session]

    var body: some View {
        let points = ProgressEngine.masteredOverTime(sessions: sessions)
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Stars earned over time")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                if points.count < 2 {
                    Text("Stars will accumulate as rounds are completed.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart(points) { p in
                        BarMark(x: .value("Date", p.date),
                                y: .value("Stars", p.cumulativeStars))
                            .foregroundStyle(Theme.starGold)
                    }
                    .frame(height: 160)
                    .accessibilityLabel("Cumulative stars earned over \(points.count) rounds")
                }
            }
        }
    }
}

/// A simple month-style calendar dotting practice days.
struct StreakCalendarCard: View {
    let sessions: [Session]
    private let span = 35

    var body: some View {
        let days = ProgressEngine.practiceDays(sessions: sessions, span: span)
        let cells = recentDays
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Practice calendar")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Last 5 weeks")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(cells, id: \.self) { day in
                        let practiced = days.contains(day)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(practiced ? Theme.accent : Theme.surfaceAlt)
                            .frame(height: 26)
                            .accessibilityLabel("\(dayLabel(day)): \(practiced ? "practiced" : "no practice")")
                    }
                }
            }
        }
    }

    private var recentDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<span).reversed().compactMap { offset in
            cal.date(byAdding: .day, value: -offset, to: today)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
