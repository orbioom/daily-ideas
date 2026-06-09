import SwiftUI
import SwiftData
import Charts

/// Progress dashboard: overall accuracy and streak, per-item mastery bars, charts
/// (accuracy over time, sessions per week), and the recent session history.
struct ProgressView_Tonic: View {
    @Query(sort: \DrillSession.date, order: .reverse) private var sessions: [DrillSession]
    @Query private var stats: [ItemStat]

    @State private var range = 14

    private var summary: ProgressEngine.Summary { ProgressEngine.summary(sessions) }
    private var dailySeries: [ProgressEngine.DailyPoint] {
        ProgressEngine.dailyAccuracy(sessions, days: range)
    }
    private var weeklySeries: [ProgressEngine.WeeklyPoint] {
        ProgressEngine.weeklySessions(sessions, weeks: 6)
    }

    var body: some View {
        ScrollView {
            if sessions.isEmpty && stats.allSatisfy({ $0.attempts == 0 }) {
                EmptyStateView(icon: "chart.xyaxis.line",
                               title: "Nothing tracked yet",
                               message: "Finish a practice run and your accuracy, mastery, and streak will appear here.")
                    .glassCard()
                    .padding(20)
            } else {
                VStack(spacing: 18) {
                    statsGrid
                    accuracyChart
                    weeklyChart
                    masterySection
                    historySection
                }
                .padding(20)
            }
        }
        .background(Brand.pageBackground)
        .navigationTitle("Progress")
    }

    // MARK: - Sections

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(summary.currentStreak)", label: "Day streak", tint: Brand.magic)
            StatTile(value: Format.percent(summary.overallAccuracy), label: "Accuracy")
            StatTile(value: "\(summary.totalSessions)", label: "Sessions")
            StatTile(value: "\(summary.totalQuestions)", label: "Questions")
        }
    }

    private var accuracyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Accuracy over time")
                Spacer()
                Picker("Range", selection: $range) {
                    Text("14d").tag(14)
                    Text("30d").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            Chart(dailySeries) { point in
                LineMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Accuracy", point.accuracy)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Brand.magic)
                if point.questions > 0 {
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Accuracy", point.accuracy)
                    )
                    .foregroundStyle(Brand.magic)
                    .symbolSize(18)
                }
            }
            .frame(height: 180)
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 0.5, 1.0]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(Format.percent(v))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: range > 14 ? 7 : 3)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .accessibilityLabel("Line chart of accuracy per day")
        }
        .glassCard()
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Sessions per week")
            Chart(weeklySeries) { point in
                BarMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Sessions", point.sessions)
                )
                .foregroundStyle(Brand.info.gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .accessibilityLabel("Bar chart of practice sessions per week")
        }
        .glassCard()
    }

    @ViewBuilder
    private var masterySection: some View {
        let practiced = DrillType.allCases.filter { type in
            !ProgressEngine.mastery(stats, type: type).isEmpty
        }
        if !practiced.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(text: "Mastery by item")
                ForEach(practiced) { type in
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: type.label)
                        ForEach(ProgressEngine.mastery(stats, type: type)) { stat in
                            MasteryBar(title: stat.displayLabel,
                                       accuracy: stat.accuracy,
                                       attempts: stat.attempts)
                        }
                    }
                }
            }
            .glassCard()
        }
    }

    @ViewBuilder
    private var historySection: some View {
        if !sessions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Recent sessions")
                ForEach(sessions.prefix(12)) { session in
                    SessionRow(session: session)
                    if session.id != sessions.prefix(12).last?.id {
                        Divider().background(Brand.hairline)
                    }
                }
            }
            .glassCard()
        }
    }
}

/// One row in the recent-session history list.
private struct SessionRow: View {
    let session: DrillSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.drillType.symbol)
                .font(.body)
                .foregroundStyle(Brand.text2)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.drillName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.percent(session.accuracy))
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Text("\(session.correct)/\(session.total)")
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.drillName), \(Format.percent(session.accuracy)) accuracy, \(session.correct) of \(session.total)")
    }
}
