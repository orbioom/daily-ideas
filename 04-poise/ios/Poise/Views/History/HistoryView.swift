import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \BreakRecord.date, order: .reverse) private var records: [BreakRecord]
    @Query private var schedules: [UserSchedule]
    @Environment(\.modelContext) private var modelContext

    private var schedule: UserSchedule {
        schedules.first ?? UserSchedule()
    }

    private var completedRecords: [BreakRecord] {
        records.filter { $0.wasCompleted }
    }

    private var adherencePercent: Double {
        guard !records.isEmpty else { return 0 }
        return Double(completedRecords.count) / Double(records.count) * 100
    }

    // Last 30 days break counts
    private var dailyData: [(Date, Int)] {
        let calendar = Calendar.current
        return (0..<30).reversed().compactMap { offset -> (Date, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
            let count = records.filter { $0.date >= startOfDay && $0.date < endOfDay && $0.wasCompleted }.count
            return (startOfDay, count)
        }
    }

    // Last 60 days for calendar grid
    private var calendarDays: [(Date, CalendarDayStatus)] {
        let calendar = Calendar.current
        let goal = max(1, schedule.dailyBreakGoal)
        return (0..<60).reversed().compactMap { offset -> (Date, CalendarDayStatus)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
            let completed = records.filter { $0.date >= startOfDay && $0.date < endOfDay && $0.wasCompleted }.count
            let status: CalendarDayStatus
            if completed == 0 {
                status = .none
            } else if completed >= goal {
                status = .goalMet
            } else {
                status = .partial
            }
            return (startOfDay, status)
        }
    }

    enum CalendarDayStatus {
        case none, partial, goalMet

        var color: Color {
            switch self {
            case .none: return Color(.systemFill)
            case .partial: return .yellow.opacity(0.7)
            case .goalMet: return .green
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak + Adherence header
                    statsHeader

                    // Bar chart
                    chartSection

                    // Calendar grid
                    calendarSection

                    // Session list
                    sessionListSection
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("History")
            .background(PoiseTheme.backgroundSecondary)
        }
    }

    private var statsHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                statBlock(
                    label: "Current Streak",
                    value: "\(schedule.currentStreakDays)",
                    suffix: "days",
                    icon: "flame.fill",
                    color: .orange
                )
                statBlock(
                    label: "Adherence",
                    value: String(format: "%.0f", adherencePercent),
                    suffix: "%",
                    icon: "chart.pie.fill",
                    color: .green
                )
                statBlock(
                    label: "Total Breaks",
                    value: "\(completedRecords.count)",
                    suffix: "",
                    icon: "checkmark.circle.fill",
                    color: PoiseTheme.sky
                )
            }

            StreakBadgeView(streak: schedule.currentStreakDays)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func statBlock(label: String, value: String, suffix: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title.weight(.bold))
                    .foregroundColor(PoiseTheme.textPrimary)
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption)
                        .foregroundColor(PoiseTheme.textSecondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundColor(PoiseTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(PoiseTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breaks Per Day (Last 30 Days)")
                .font(.headline)
                .foregroundColor(PoiseTheme.textPrimary)
                .padding(.horizontal, 20)

            if dailyData.allSatisfy({ $0.1 == 0 }) {
                emptyChartPlaceholder
            } else {
                Chart {
                    ForEach(dailyData, id: \.0) { item in
                        BarMark(
                            x: .value("Date", item.0, unit: .day),
                            y: .value("Breaks", item.1)
                        )
                        .foregroundStyle(PoiseTheme.sky.gradient)
                        .cornerRadius(4)
                    }

                    RuleMark(y: .value("Goal", schedule.dailyBreakGoal))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundStyle(Color.green.opacity(0.6))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine().foregroundStyle(Color(.separator))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(PoiseTheme.textMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color(.separator))
                        AxisValueLabel().foregroundStyle(PoiseTheme.textMuted)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.largeTitle)
                    .foregroundColor(PoiseTheme.textMuted)
                Text("No break data yet")
                    .font(.subheadline)
                    .foregroundColor(PoiseTheme.textMuted)
            }
            Spacer()
        }
        .padding(40)
        .background(PoiseTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last 60 Days")
                    .font(.headline)
                    .foregroundColor(PoiseTheme.textPrimary)
                Spacer()
                HStack(spacing: 10) {
                    legendDot(color: .green, label: "Goal met")
                    legendDot(color: .yellow.opacity(0.7), label: "Partial")
                    legendDot(color: Color(.systemFill), label: "None")
                }
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, item in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.1.color)
                        .frame(height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(PoiseTheme.textMuted)
        }
    }

    private var sessionListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .foregroundColor(PoiseTheme.textPrimary)
                .padding(.horizontal, 20)

            if records.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundColor(PoiseTheme.textMuted)
                        Text("No sessions yet. Take your first break!")
                            .font(.subheadline)
                            .foregroundColor(PoiseTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(32)
            } else {
                ForEach(records.prefix(20)) { record in
                    HStack(spacing: 14) {
                        Image(systemName: record.wasCompleted ? "checkmark.circle.fill" : "forward.circle.fill")
                            .foregroundColor(record.wasCompleted ? .green : .orange)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.exerciseName)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(PoiseTheme.textPrimary)
                            HStack(spacing: 8) {
                                Text(record.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(PoiseTheme.textMuted)
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(PoiseTheme.textMuted)
                                Text(record.date, style: .time)
                                    .font(.caption)
                                    .foregroundColor(PoiseTheme.textMuted)
                            }
                        }

                        Spacer()

                        Text(record.wasCompleted ? "Done" : "Skipped")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(record.wasCompleted ? .green : .orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background((record.wasCompleted ? Color.green : Color.orange).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
