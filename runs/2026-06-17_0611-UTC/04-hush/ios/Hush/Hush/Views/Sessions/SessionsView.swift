import SwiftUI
import SwiftData
import Charts

/// Listening history + stats: minutes-per-night bar chart, most-used sounds,
/// total hours, average session, and a nightly streak. Empty state when there's
/// no history yet.
struct SessionsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @Query(sort: \ListeningSession.startedAt, order: .reverse) private var sessions: [ListeningSession]

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    HushCard {
                        EmptyStateView(
                            icon: "chart.bar.xaxis",
                            title: "No sessions yet",
                            message: "Start a sleep timer on the Timer tab. When it finishes, your night is logged here with charts and a streak."
                        )
                    }
                    .padding(16)
                } else {
                    VStack(spacing: 18) {
                        statsRow
                        nightlyChartCard
                        topSoundsCard
                        historyCard
                    }
                    .padding(16)
                }
            }
            .scrollContentBackground(.hidden)
            .hushScreenBackground(scheme)
            .navigationTitle("Sessions")
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        let totalSec = SessionStats.totalSeconds(sessions)
        let streak = SessionStats.currentStreak(sessions)
        let avg = SessionStats.averageMinutes(sessions)
        return HStack(spacing: 12) {
            statTile(value: Formatting.hoursLabel(fromSeconds: totalSec), label: "Total", icon: "clock.fill")
            statTile(value: "\(streak)", label: "Night streak", icon: "flame.fill")
            statTile(value: "\(avg)m", label: "Avg / night", icon: "moon.fill")
        }
    }

    private func statTile(value: String, label: String, icon: String) -> some View {
        HushCard(padding: 14) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(HushTheme.teal)
                    .accessibilityHidden(true)
                Text(value)
                    .font(HushTheme.numeral(22))
                    .foregroundStyle(HushTheme.primaryText(scheme))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(HushTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Nightly chart

    private var nightlyChartCard: some View {
        let data = SessionStats.nightlyMinutes(sessions, days: 14)
        let maxMinutes = data.map { $0.minutes }.max() ?? 0
        return HushCard {
            VStack(alignment: .leading, spacing: 12) {
                HushSectionHeader(title: "Minutes per night", systemImage: "chart.bar.fill")
                if maxMinutes == 0 {
                    Text("No sessions in the last two weeks.")
                        .font(.subheadline)
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart(data) { item in
                        BarMark(
                            x: .value("Night", item.date, unit: .day),
                            y: .value("Minutes", item.minutes)
                        )
                        .foregroundStyle(HushTheme.teal.gradient)
                        .cornerRadius(4)
                        .accessibilityLabel(Formatting.dayMonth.string(from: item.date))
                        .accessibilityValue("\(item.minutes) minutes")
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 3)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Bar chart of listening minutes per night over the last two weeks.")
                }
            }
        }
    }

    // MARK: - Top sounds

    private var topSoundsCard: some View {
        let top = SessionStats.topSounds(sessions, limit: 5)
        let maxCount = top.map { $0.count }.max() ?? 1
        return HushCard {
            VStack(alignment: .leading, spacing: 12) {
                HushSectionHeader(title: "Most-used sounds", systemImage: "waveform")
                if top.isEmpty {
                    Text("No sounds recorded yet.")
                        .font(.subheadline)
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                } else {
                    ForEach(top) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.type.symbol)
                                .font(.subheadline)
                                .foregroundStyle(item.type.tint)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text(item.type.title)
                                .font(.subheadline)
                                .foregroundStyle(HushTheme.primaryText(scheme))
                                .frame(width: 110, alignment: .leading)
                            GeometryReader { geo in
                                let frac = maxCount > 0 ? Double(item.count) / Double(maxCount) : 0
                                ZStack(alignment: .leading) {
                                    Capsule().fill(HushTheme.track(scheme))
                                    Capsule()
                                        .fill(item.type.tint)
                                        .frame(width: max(6, geo.size.width * frac))
                                }
                            }
                            .frame(height: 10)
                            Text("\(item.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(HushTheme.secondaryText(scheme))
                                .frame(width: 28, alignment: .trailing)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(item.type.title): used in \(item.count) sessions")
                    }
                }
            }
        }
    }

    // MARK: - History

    private var historyCard: some View {
        HushCard {
            VStack(alignment: .leading, spacing: 12) {
                HushSectionHeader(title: "History", systemImage: "list.bullet")
                LazyVStack(spacing: 0) {
                    ForEach(sessions) { session in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.mixName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(HushTheme.primaryText(scheme))
                                Text(Formatting.dayMonth.string(from: session.startedAt))
                                    .font(.caption)
                                    .foregroundStyle(HushTheme.secondaryText(scheme))
                            }
                            Spacer()
                            Text(Formatting.minutesLabel(session.durationSeconds / 60))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HushTheme.teal)
                        }
                        .padding(.vertical, 10)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(session.mixName), \(Formatting.dayMonth.string(from: session.startedAt)), \(Formatting.minutesLabel(session.durationSeconds / 60))")
                        if session.id != sessions.last?.id {
                            Divider().overlay(HushTheme.hairline(scheme))
                        }
                    }
                }
            }
        }
    }
}
