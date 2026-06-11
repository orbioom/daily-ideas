import SwiftUI
import SwiftData
import Charts

struct RehearsalsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RehearsalSession.date, order: .reverse) private var sessions: [RehearsalSession]

    private var totalSeconds: TimeInterval { sessions.reduce(0) { $0 + $1.duration } }
    private var completedCount: Int { sessions.filter(\.completed).count }
    private var averageWPM: Int {
        let paced = sessions.filter { $0.wordsPerMinute > 0 }
        guard !paced.isEmpty else { return 0 }
        return paced.reduce(0) { $0 + $1.wordsPerMinute } / paced.count
    }

    /// Last 14 days of practice, in minutes.
    private var dailyMinutes: [(day: Date, minutes: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<14).reversed().compactMap { back in
            guard let day = cal.date(byAdding: .day, value: -back, to: today) else { return nil }
            let secs = sessions
                .filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.duration }
            return (day, secs / 60)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No rehearsals yet",
                        message: "Run any script in the prompter and your practice time, pace and completions will show up here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statRow
                            chartCard
                            sessionList
                        }
                        .padding(16)
                    }
                    .background(Theme.bgPrimary)
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Rehearsals")
        }
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            statTile(value: TextStats.formatMinutes(totalSeconds), label: "practiced")
            statTile(value: "\(completedCount)", label: "full reads")
            statTile(value: averageWPM > 0 ? "\(averageWPM)" : "—", label: "avg wpm")
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .lecternCard()
        .accessibilityElement(children: .combine)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Practice — last 14 days")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Chart(dailyMinutes, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day, unit: .day),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(3)
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .accessibilityLabel("Bar chart of practice minutes per day over the last 14 days")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lecternCard()
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent sessions")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 6)
            ForEach(sessions.prefix(30)) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.script?.title ?? "Deleted script")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(session.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(TextStats.formatDuration(session.duration))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 4) {
                            if session.completed {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.accent)
                                    .accessibilityHidden(true)
                            }
                            Text(session.wordsPerMinute > 0 ? "\(session.wordsPerMinute) wpm" : "partial")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(session.script?.title ?? "Deleted script"), \(TextStats.formatDuration(session.duration)), \(session.completed ? "completed" : "partial")")
                Divider()
            }
        }
        .lecternCard()
    }
}
