import SwiftUI
import SwiftData
import Charts

struct JournalView: View {
    @Query(sort: \CompletedSession.date, order: .reverse) private var history: [CompletedSession]
    @Environment(\.modelContext) private var ctx

    private var totalMinutes: Int { history.reduce(0) { $0 + $1.durationMinutes } }
    private var avgMoodBefore: Double {
        guard !history.isEmpty else { return 0 }
        return Double(history.reduce(0) { $0 + $1.moodBefore }) / Double(history.count)
    }
    private var avgMoodAfter: Double {
        guard !history.isEmpty else { return 0 }
        return Double(history.reduce(0) { $0 + $1.moodAfter }) / Double(history.count)
    }

    private var last14Days: [(date: Date, minutes: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<14).map { daysAgo in
            let d = cal.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let mins = history.filter { cal.startOfDay(for: $0.date) == d }.reduce(0) { $0 + $1.durationMinutes }
            return (date: d, minutes: mins)
        }.reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if history.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(FlowTheme.sage.opacity(0.4))
                            .accessibilityHidden(true)
                        Text("No sessions yet")
                            .font(.headline)
                            .foregroundStyle(FlowTheme.text)
                        Text("Complete a session to start your journal.")
                            .foregroundStyle(FlowTheme.subtle)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    VStack(spacing: 20) {
                        statsCards
                        activityChart
                        sessionList
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
            .background(FlowTheme.bg)
            .navigationTitle("Journal")
        }
    }

    @ViewBuilder
    private var statsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(value: "\(history.count)", label: "Sessions", color: FlowTheme.sage)
            StatCard(value: "\(totalMinutes)", label: "Minutes", color: .orange)
            StatCard(value: String(format: "+%.1f", avgMoodAfter - avgMoodBefore), label: "Mood Lift", color: .purple)
        }
    }

    @ViewBuilder
    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity (14 days)")
                .font(.headline)
                .foregroundStyle(FlowTheme.text)

            Chart(last14Days, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(FlowTheme.sage.gradient)
                .cornerRadius(4)
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { v in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .foregroundStyle(FlowTheme.subtle)
                }
            }
        }
        .padding()
        .background(FlowTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .foregroundStyle(FlowTheme.text)

            ForEach(history) { session in
                SessionHistoryRow(session: session)
            }
        }
    }
}

private struct StatCard: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(FlowTheme.subtle)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(FlowTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

private struct SessionHistoryRow: View {
    let session: CompletedSession
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FlowTheme.text)
                Text(session.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(FlowTheme.subtle)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.durationMinutes) min")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(FlowTheme.subtle)
                HStack(spacing: 4) {
                    Text(FlowTheme.moodEmoji(session.moodBefore)).font(.caption2).accessibilityHidden(true)
                    Image(systemName: "arrow.right").font(.caption2).foregroundStyle(FlowTheme.subtle.opacity(0.5))
                    Text(FlowTheme.moodEmoji(session.moodAfter)).font(.caption2).accessibilityHidden(true)
                }
            }
        }
        .padding()
        .background(FlowTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.sessionName), \(session.durationMinutes) minutes, mood before \(session.moodBefore), mood after \(session.moodAfter)")
    }
}
