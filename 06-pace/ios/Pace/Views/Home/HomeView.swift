import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \RunSession.date, order: .reverse) private var sessions: [RunSession]
    @AppStorage("pace_use_km") private var useKm = true
    @AppStorage("pace_weekly_goal_km") private var weeklyGoalKm = 20.0
    @AppStorage("pace_seeded") private var seeded = false
    @Environment(\.modelContext) private var modelContext

    private var todaySessions: [RunSession] {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.date >= today }
    }

    private var weeklyDistanceKm: Double {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) ?? Date()
        return sessions.filter { $0.date >= startOfWeek }.reduce(0.0) { $0 + $1.distanceKm }
    }

    private var recentSessions: [RunSession] {
        Array(sessions.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greetingText)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Today's summary
                    if !todaySessions.isEmpty {
                        TodaySummaryCard(sessions: todaySessions, useKm: useKm)
                            .padding(.horizontal)
                    }

                    // Weekly goal ring
                    WeeklyGoalCard(
                        current: weeklyDistanceKm,
                        goal: weeklyGoalKm,
                        useKm: useKm
                    )
                    .padding(.horizontal)

                    // Recent runs
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Runs")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(recentSessions) { session in
                                NavigationLink(destination: RunDetailView(session: session)) {
                                    RunCard(session: session, useKm: useKm)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                                if session.id != recentSessions.last?.id {
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                    } else {
                        EmptyHomeState()
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Pace")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !seeded {
                    seedSampleData()
                    seeded = true
                }
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    private func seedSampleData() {
        let calendar = Calendar.current
        let now = Date()

        let sampleData: [(ActivityType, Double, Double, Double, Int)] = [
            (.run, 5200, 1620, 45, -1),
            (.run, 8100, 2700, 82, -2),
            (.walk, 3200, 2400, 18, -3),
            (.run, 10050, 3540, 110, -5),
            (.hike, 6800, 4200, 280, -7),
        ]

        for (type, distance, duration, elevation, dayOffset) in sampleData {
            let session = RunSession(activityType: type)
            session.date = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            session.distanceMeters = distance
            session.duration = duration
            session.elevationGainMeters = elevation
            session.averageSpeedMps = distance / duration
            session.maxSpeedMps = (distance / duration) * 1.3
            let durationHours = duration / 3600
            let met: Double = type == .run ? 8.5 : (type == .walk ? 3.5 : 5.0)
            session.calories = met * 70 * durationHours
            modelContext.insert(session)
        }

        try? modelContext.save()
    }
}

private struct TodaySummaryCard: View {
    let sessions: [RunSession]
    let useKm: Bool

    private var totalDistance: Double { sessions.reduce(0) { $0 + $1.distanceKm } }
    private var totalDuration: Double { sessions.reduce(0) { $0 + $1.duration } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(useKm ? String(format: "%.2f", totalDistance) : String(format: "%.2f", totalDistance * 0.621371))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(PaceTheme.accent)
                    Text(useKm ? "km" : "miles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDuration(totalDuration))
                        .font(.title)
                        .fontWeight(.bold)
                    Text("time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sessions.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(sessions.count == 1 ? "activity" : "activities")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

private struct WeeklyGoalCard: View {
    let current: Double
    let goal: Double
    let useKm: Bool

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Goal")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 20) {
                PaceRing(progress: progress, size: 80, lineWidth: 10)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(useKm ? String(format: "%.1f", current) : String(format: "%.1f", current * 0.621371))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/ \(useKm ? String(format: "%.0f km", goal) : String(format: "%.0f mi", goal * 0.621371))")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.0f%%", progress * 100) + " of weekly goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct EmptyHomeState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundStyle(PaceTheme.accent.opacity(0.6))
            Text("No runs yet")
                .font(.headline)
            Text("Tap Run to start tracking your first activity.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
