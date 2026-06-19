import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @Query private var settingsQuery: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var showSettings = false
    @State private var navigateToCurriculum = false

    private var settings: UserSettings? { settingsQuery.first }

    private var todayMinutes: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return sessions
            .filter { calendar.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.durationSeconds }
            / 60
    }

    private var streakCount: Int {
        settings?.streakCount ?? 0
    }

    private var goalMinutes: Int {
        settings?.dailyGoalMinutes ?? 10
    }

    private var goalProgress: Double {
        min(Double(todayMinutes) / Double(goalMinutes), 1.0)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.subheadline)
                                .foregroundStyle(KeysTheme.textSecondary)
                            Text("Ready to practice?")
                                .font(.title.bold())
                                .foregroundStyle(KeysTheme.text)
                        }
                        Spacer()
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(KeysTheme.textSecondary)
                        }
                        .accessibilityLabel("Settings")
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Streak + Goal card
                    HStack(spacing: 16) {
                        StreakCard(streakCount: streakCount)
                        GoalProgressCard(
                            todayMinutes: todayMinutes,
                            goalMinutes: goalMinutes,
                            progress: goalProgress
                        )
                    }
                    .padding(.horizontal)

                    // Today's Practice card
                    TodayPracticeCard()
                        .padding(.horizontal)

                    // Recent sessions
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Sessions")
                                .font(.headline)
                                .foregroundStyle(KeysTheme.text)
                                .padding(.horizontal)

                            ForEach(sessions.prefix(3)) { session in
                                RecentSessionRow(session: session)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        EmptyPracticeView()
                            .padding(.horizontal)
                    }

                    // Quick start buttons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Start")
                            .font(.headline)
                            .foregroundStyle(KeysTheme.text)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Curriculum.modules) { module in
                                    NavigationLink(destination: LessonListView(module: module)) {
                                        QuickStartCard(module: module)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
            }
            .background(KeysTheme.background)
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct StreakCard: View {
    let streakCount: Int

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(KeysTheme.accent.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: streakCount > 0 ? 1.0 : 0.0)
                    .stroke(KeysTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(streakCount)")
                        .font(.title3.bold())
                        .foregroundStyle(KeysTheme.text)
                    Text("days")
                        .font(.caption2)
                        .foregroundStyle(KeysTheme.textSecondary)
                }
            }
            Text("Streak")
                .font(.caption.weight(.medium))
                .foregroundStyle(KeysTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct GoalProgressCard: View {
    let todayMinutes: Int
    let goalMinutes: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Goal")
                .font(.caption.weight(.medium))
                .foregroundStyle(KeysTheme.textSecondary)

            Text("\(todayMinutes)/\(goalMinutes) min")
                .font(.title3.bold())
                .foregroundStyle(KeysTheme.text)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(KeysTheme.accent.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(KeysTheme.accent)
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            Text(progress >= 1.0 ? "Goal reached!" : "\(goalMinutes - todayMinutes) min to go")
                .font(.caption)
                .foregroundStyle(progress >= 1.0 ? KeysTheme.accent : KeysTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TodayPracticeCard: View {
    var body: some View {
        NavigationLink(destination: CurriculumView()) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(KeysTheme.accent)
                        .frame(width: 52, height: 52)
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Practice")
                        .font(.headline)
                        .foregroundStyle(KeysTheme.text)
                    Text("Continue where you left off")
                        .font(.subheadline)
                        .foregroundStyle(KeysTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(KeysTheme.textSecondary)
            }
            .padding()
            .background(KeysTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Today's Practice — continue where you left off")
    }
}

struct RecentSessionRow: View {
    let session: PracticeSession

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: session.date, relativeTo: .now)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(KeysTheme.accent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "music.note")
                    .font(.subheadline)
                    .foregroundStyle(KeysTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.lessonTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KeysTheme.text)
                Text(session.moduleTitle)
                    .font(.caption)
                    .foregroundStyle(KeysTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.score)%")
                    .font(.subheadline.bold())
                    .foregroundStyle(session.score >= 80 ? KeysTheme.accent : KeysTheme.textSecondary)
                Text(timeAgo)
                    .font(.caption)
                    .foregroundStyle(KeysTheme.textSecondary)
            }
        }
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EmptyPracticeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pianokeys")
                .font(.system(size: 40))
                .foregroundStyle(KeysTheme.accent.opacity(0.6))
            Text("No sessions yet")
                .font(.headline)
                .foregroundStyle(KeysTheme.text)
            Text("Complete your first lesson to see it here")
                .font(.subheadline)
                .foregroundStyle(KeysTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickStartCard: View {
    let module: CurriculumModule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: module.icon)
                .font(.title2)
                .foregroundStyle(module.color)

            Text(module.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KeysTheme.text)
                .lineLimit(2)

            Text("\(module.lessons.count) lessons")
                .font(.caption)
                .foregroundStyle(KeysTheme.textSecondary)
        }
        .padding()
        .frame(width: 130, alignment: .leading)
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
