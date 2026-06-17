import SwiftUI
import SwiftData
import Charts

/// A 7-day bar chart of practice minutes derived from the SwiftData practice log.
struct PracticeChart: View {
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \PracticeLog.date, order: .reverse) private var logs: [PracticeLog]

    private struct DayTotal: Identifiable {
        let id = UUID()
        let day: Date
        let minutes: Double
        let label: String
    }

    /// Aggregate the last 7 calendar days of minutes.
    private var weekTotals: [DayTotal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var result: [DayTotal] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let total = logs
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.minutes }
            result.append(DayTotal(day: day, minutes: total, label: formatter.string(from: day)))
        }
        return result
    }

    private var totalMinutes: Double { weekTotals.reduce(0) { $0 + $1.minutes } }

    var body: some View {
        if logs.isEmpty {
            Text("Start the metronome to begin logging practice minutes.")
                .font(.subheadline)
                .foregroundStyle(PitchTheme.secondaryText(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(Int(totalMinutes.rounded())) min")
                    .font(PitchTheme.mono(28, weight: .bold))
                    .foregroundStyle(PitchTheme.primaryText(scheme))
                    .accessibilityLabel("Total practice this week")
                    .accessibilityValue("\(Int(totalMinutes.rounded())) minutes")

                Chart(weekTotals) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(PitchTheme.indigo.gradient)
                    .cornerRadius(5)
                    .accessibilityLabel(item.label)
                    .accessibilityValue("\(Int(item.minutes.rounded())) minutes")
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 160)
            }
        }
    }
}
