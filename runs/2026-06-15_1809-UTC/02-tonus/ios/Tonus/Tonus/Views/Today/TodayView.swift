import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \TrainingProgram.sortIndex) private var programs: [TrainingProgram]
    @Query(sort: \SessionLog.date, order: .reverse) private var logs: [SessionLog]

    @State private var sessionProgram: TrainingProgram?
    @State private var showSettings = false

    private var stats: StatsEngine { StatsEngine(logs: logs) }

    /// The recommended program: the user's default if present, else the first beginner program.
    private var recommended: TrainingProgram? {
        if let match = programs.first(where: { $0.name == settings.defaultProgramName }) {
            return match
        }
        return programs.sorted { $0.sortIndex < $1.sortIndex }.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let program = recommended {
                        heroCard(program)
                        statsRow
                        weeklyCard
                        recentSection
                    } else {
                        EmptyStateView(
                            symbol: "figure.mind.and.body",
                            title: "Welcome to Tonus",
                            message: "Your programs are getting ready. Pull down to refresh if this lingers."
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .fullScreenCover(item: $sessionProgram) { program in
                SessionPlayerView(program: program)
            }
        }
    }

    // MARK: Hero

    private func heroCard(_ program: TrainingProgram) -> some View {
        let engine = SessionEngine(program: program)
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(program.levelLabel)
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.18)))
            }
            Text(program.name)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(.white)
            Text(program.summary)
                .font(Theme.rounded(15))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                metaPill(symbol: "repeat", text: "\(engine.totalReps) reps")
                metaPill(symbol: "square.stack.3d.up", text: "\(program.sets) set\(program.sets == 1 ? "" : "s")")
                metaPill(symbol: "clock", text: engine.durationLabel)
            }
            Button {
                Haptics.tap(enabled: settings.hapticsEnabled)
                sessionProgram = program
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").accessibilityHidden(true)
                    Text("Start session").font(Theme.rounded(17, .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(Theme.accentDeep)
                .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(.white))
            }
            .buttonStyle(PressableScale())
            .accessibilityHint("Begins a guided \(program.name) session")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.heroGradient)
        )
    }

    private func metaPill(symbol: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 12, weight: .semibold)).accessibilityHidden(true)
            Text(text).font(Theme.rounded(13, .medium))
        }
        .foregroundStyle(.white.opacity(0.95))
    }

    // MARK: Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(stats.currentStreak)",
                     label: "day streak",
                     symbol: "flame.fill",
                     tint: Theme.warn)
            StatTile(value: "\(stats.sessionsThisWeek)",
                     label: "this week",
                     symbol: "calendar",
                     tint: Theme.accent)
            StatTile(value: "\(stats.totalSessions)",
                     label: "total",
                     symbol: "checkmark.circle.fill",
                     tint: Theme.good)
        }
    }

    // MARK: Weekly ring

    private var weeklyCard: some View {
        let goal = settings.weeklyGoal
        let done = stats.sessionsThisWeek
        let progress = stats.adherence(weeklyGoal: goal)
        return HStack(spacing: 18) {
            ProgressRing(progress: progress,
                         size: 96,
                         label: "\(done)/\(goal)",
                         caption: "sessions")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Weekly goal")
                .accessibilityValue("\(done) of \(goal) sessions, \(Int((progress * 100).rounded())) percent")
            VStack(alignment: .leading, spacing: 6) {
                Text("This week")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text(weeklyMessage(done: done, goal: goal))
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .cardSurface()
    }

    private func weeklyMessage(done: Int, goal: Int) -> String {
        if done == 0 { return "Begin your first session this week — small, steady reps add up." }
        if done >= goal { return "Goal reached. Beautifully consistent — keep the rhythm going." }
        let left = goal - done
        return "\(left) more session\(left == 1 ? "" : "s") to hit your weekly goal."
    }

    // MARK: Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent sessions", systemImage: "clock.arrow.circlepath")
            if logs.isEmpty {
                EmptyStateView(
                    symbol: "leaf.fill",
                    title: "No sessions yet",
                    message: "Begin your first session and it will appear here."
                )
                .cardSurface()
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(stats.recent(limit: 6)) { log in
                        RecentRow(log: log)
                    }
                }
            }
        }
    }
}

/// A compact row summarizing one past session.
struct RecentRow: View {
    let log: SessionLog

    private var relativeDay: String {
        let cal = Calendar.current
        if cal.isDateInToday(log.date) { return "Today" }
        if cal.isDateInYesterday(log.date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: log.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.finished ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(log.finished ? Theme.good : Theme.inkFaint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(log.programName)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(relativeDay) · \(log.completedReps)/\(log.totalReps) reps")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text("\(max(1, Int((log.durationMinutes).rounded()))) min")
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(log.programName), \(relativeDay), \(log.completedReps) of \(log.totalReps) reps, \(log.finished ? "finished" : "stopped early")")
    }
}
