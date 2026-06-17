import SwiftUI
import SwiftData
import Charts

/// Completed-session history with stats, charts and a session list. Empty state
/// when nothing has been completed yet.
struct HistoryView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings

    @Query(sort: \CompletedSession.date, order: .reverse) private var completed: [CompletedSession]

    var body: some View {
        NavigationStack {
            Group {
                if completed.isEmpty {
                    empty
                } else {
                    content
                }
            }
            .laceScreenBackground(scheme)
            .navigationTitle("History")
        }
    }

    private var content: some View {
        let stats = ProgressEngine.stats(completed)
        let weekly = ProgressEngine.minutesPerWeek(completed)
        let cumulative = ProgressEngine.cumulativeSessions(completed)

        return ScrollView {
            LazyVStack(spacing: 16) {
                // Stats grid
                LaceCard {
                    VStack(spacing: 14) {
                        HStack(spacing: 0) {
                            StatPill(value: "\(stats.totalSessions)", label: "Sessions", systemImage: "figure.run")
                            Divider().frame(height: 36)
                            StatPill(value: "\(stats.totalMinutes)", label: "Minutes", systemImage: "clock.fill")
                        }
                        Divider().background(Theme.hairline(scheme))
                        HStack(spacing: 0) {
                            StatPill(value: "\(stats.currentStreakDays)", label: "Streak", systemImage: "flame.fill")
                            Divider().frame(height: 36)
                            StatPill(value: "\(stats.longestStreakDays)", label: "Longest", systemImage: "crown.fill")
                            Divider().frame(height: 36)
                            StatPill(value: "\(stats.runMinutes)", label: "Run min", systemImage: "bolt.fill")
                        }
                    }
                }

                // Minutes per week
                LaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        LaceSectionHeader(title: "Minutes per week", systemImage: "chart.bar.fill")
                        minutesChart(weekly)
                    }
                }

                // Sessions over time
                LaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        LaceSectionHeader(title: "Sessions over time", systemImage: "chart.xyaxis.line")
                        cumulativeChart(cumulative)
                    }
                }

                // Session list
                LaceCard {
                    VStack(alignment: .leading, spacing: 0) {
                        LaceSectionHeader(title: "Recent sessions")
                            .padding(.bottom, 8)
                        ForEach(completed) { session in
                            sessionRow(session)
                            if session.id != completed.last?.id {
                                Divider().background(Theme.hairline(scheme))
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Charts

    private func minutesChart(_ weekly: [WeekBucket]) -> some View {
        Chart {
            ForEach(weekly) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", bucket.minutes)
                )
                .foregroundStyle(Theme.coral)
                .cornerRadius(5)
            }
        }
        .chartYAxis { AxisMarks(position: .leading) }
        .frame(height: 200)
        .accessibilityLabel("Minutes trained per week")
        .accessibilityValue(weeklySummary(weekly))
    }

    private func cumulativeChart(_ points: [CumulativePoint]) -> some View {
        Chart {
            ForEach(points) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Sessions", p.count)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Theme.teal)
                .lineStyle(StrokeStyle(lineWidth: 3))
                AreaMark(
                    x: .value("Date", p.date),
                    y: .value("Sessions", p.count)
                )
                .foregroundStyle(Theme.teal.opacity(0.15))
            }
        }
        .chartYAxis { AxisMarks(position: .leading) }
        .frame(height: 180)
        .accessibilityLabel("Cumulative sessions completed over time")
        .accessibilityValue("\(points.last?.count ?? 0) sessions total")
    }

    private func weeklySummary(_ weekly: [WeekBucket]) -> String {
        guard !weekly.isEmpty else { return "No data yet" }
        let total = weekly.reduce(0) { $0 + $1.minutes }
        let avg = weekly.isEmpty ? 0 : total / weekly.count
        return "Across \(weekly.count) weeks, about \(avg) minutes per week"
    }

    // MARK: - Session row

    private func sessionRow(_ session: CompletedSession) -> some View {
        let planTitle = PlanResolver.shared.plan(id: session.planId)?.title ?? "Session"
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.coral.opacity(0.16)).frame(width: 40, height: 40)
                Image(systemName: "figure.run")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.coral)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(planTitle) · W\(session.week) S\(session.sessionIndex + 1)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText(scheme))
                HStack(spacing: 8) {
                    Text(Fmt.mediumDate(session.date))
                    Text("·")
                    Text(Fmt.minutes(session.durationSeconds))
                    if let dist = session.distanceMeters {
                        Text("·")
                        Text(settings.units.format(dist))
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.secondaryText(scheme))
            }
            Spacer(minLength: 0)
            if let felt = session.feltRating {
                HStack(spacing: 1) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.warmup)
                    Text("\(felt)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
                .accessibilityLabel("Felt \(felt) out of 5")
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(planTitle), week \(session.week) session \(session.sessionIndex + 1), \(Fmt.mediumDate(session.date)), \(Fmt.minutes(session.durationSeconds))")
    }

    private var empty: some View {
        ScrollView {
            EmptyStateView(
                icon: "chart.bar.xaxis",
                title: "No runs yet",
                message: "Finish your first guided session and your stats, streak and charts will appear here."
            )
            .padding(.top, 70)
        }
    }
}
