import SwiftUI
import SwiftData

struct SessionListView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @State private var showingLogSession = false

    private var monthlyGroups: [(String, [TrainingSession])] {
        BeltEngine.sessionsByMonth(sessions)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DojoTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Stats Row
                        StatsRowView(sessions: sessions)
                            .padding(.horizontal)

                        if sessions.isEmpty {
                            EmptySessionsView()
                        } else {
                            // Monthly grouped list
                            ForEach(monthlyGroups, id: \.0) { month, monthSessions in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(month)
                                        .font(.headline)
                                        .foregroundColor(DojoTheme.subtleText)
                                        .padding(.horizontal)

                                    ForEach(monthSessions) { session in
                                        NavigationLink(destination: SessionDetailView(session: session)) {
                                            SessionRowView(session: session)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingLogSession = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(DojoTheme.crimson)
                                .clipShape(Circle())
                                .shadow(color: DojoTheme.crimson.opacity(0.4), radius: 8, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Training Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
            .sheet(isPresented: $showingLogSession) {
                LogSessionView()
            }
        }
        .tint(DojoTheme.crimson)
    }
}

// MARK: - Stats Row

struct StatsRowView: View {
    let sessions: [TrainingSession]

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(BeltEngine.totalSessions(sessions))",
                label: "Sessions",
                icon: "figure.martial.arts",
                color: DojoTheme.crimson
            )
            StatCard(
                value: "\(BeltEngine.totalHours(sessions))",
                label: "Hours",
                icon: "clock.fill",
                color: DojoTheme.gold
            )
            StatCard(
                value: String(format: "%.0f%%", BeltEngine.submissionRatio(sessions) * 100),
                label: "Sub Ratio",
                icon: "checkmark.seal.fill",
                color: .green
            )
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(DojoTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: TrainingSession

    var body: some View {
        HStack(spacing: 14) {
            // Type indicator
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DojoTheme.crimson.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: session.trainingType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(DojoTheme.crimson)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.trainingType.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Label("\(session.durationMinutes)m", systemImage: "clock")
                    Label("\(session.rounds) rounds", systemImage: "arrow.counterclockwise")
                }
                .font(.caption)
                .foregroundColor(DojoTheme.subtleText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundColor(DojoTheme.subtleText)
                if session.submissionsGot > 0 || session.tapOuts > 0 {
                    HStack(spacing: 4) {
                        Text("\(session.submissionsGot)↑")
                            .foregroundColor(.green)
                        Text("\(session.tapOuts)↓")
                            .foregroundColor(DojoTheme.crimson)
                    }
                    .font(.caption.bold())
                }
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Empty State

struct EmptySessionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.martial.arts")
                .font(.system(size: 60))
                .foregroundColor(DojoTheme.subtleText)
            Text("No sessions yet")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Tap + to log your first training session")
                .font(.body)
                .foregroundColor(DojoTheme.subtleText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, 32)
    }
}

#Preview {
    SessionListView()
        .modelContainer(for: [TrainingSession.self], inMemory: true)
}
