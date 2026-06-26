import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \SwimSession.date, order: .reverse) private var sessions: [SwimSession]
    @Query private var settingsAll: [SplashSettings]
    @Environment(\.modelContext) private var context
    @State private var showingLog = false

    var useYards: Bool { settingsAll.first?.useYards ?? false }
    var weeklyGoalKm: Double { settingsAll.first?.weeklyGoalKm ?? 3.0 }

    var recentSessions: [SwimSession] { Array(sessions.prefix(5)) }

    var thisWeekDistance: Double {
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return 0 }
        return sessions
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + ($1.computedDistance > 0 ? $1.computedDistance : $1.totalDistanceMeters) }
    }

    var weeklyProgress: Double {
        min(1.0, thisWeekDistance / (weeklyGoalKm * 1000))
    }

    var lastSession: SwimSession? { sessions.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly goal ring
                    WeeklyRingCard(
                        progress: weeklyProgress,
                        current: thisWeekDistance,
                        goal: weeklyGoalKm * 1000,
                        useYards: useYards
                    )

                    // Quick stats
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Total Sessions",
                            value: "\(sessions.count)",
                            icon: "figure.pool.swim",
                            color: SplashTheme.accent
                        )
                        StatCard(
                            title: "Total Distance",
                            value: metersToDisplay(sessions.reduce(0) { $0 + ($1.computedDistance > 0 ? $1.computedDistance : $1.totalDistanceMeters) }, useYards: useYards),
                            icon: "arrow.left.and.right",
                            color: Color(red: 0.28, green: 0.52, blue: 0.93)
                        )
                    }

                    // Log button
                    Button {
                        showingLog = true
                    } label: {
                        Label("Log Swim Session", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SplashTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Log a new swim session")

                    // Recent sessions
                    if !recentSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Sessions")
                                .font(.headline)
                                .padding(.horizontal, 2)
                            ForEach(recentSessions) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    SessionRow(session: session, useYards: useYards)
                                        .padding(12)
                                        .background(SplashTheme.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .tint(.primary)
                            }
                        }
                    } else {
                        ContentUnavailableView {
                            Label("No Sessions Yet", systemImage: "drop.circle")
                        } description: {
                            Text("Tap 'Log Swim Session' to get started!")
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Splash")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingLog) {
                LogSessionView()
            }
        }
    }
}

private struct WeeklyRingCard: View {
    let progress: Double
    let current: Double
    let goal: Double
    let useYards: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(SplashTheme.accent.opacity(0.15), lineWidth: 12)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: reduceMotion ? progress : progress)
                    .stroke(SplashTheme.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: progress)
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.title3.bold())
                        .foregroundStyle(SplashTheme.accent)
                }
            }
            .accessibilityLabel("Weekly goal: \(Int(progress * 100))% complete")

            VStack(alignment: .leading, spacing: 6) {
                Text("This Week")
                    .font(.headline)
                Text(metersToDisplay(current, useYards: useYards))
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("of \(metersToDisplay(goal, useYards: useYards)) goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if progress >= 1.0 {
                    Label("Goal achieved!", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding()
        .background(SplashTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
