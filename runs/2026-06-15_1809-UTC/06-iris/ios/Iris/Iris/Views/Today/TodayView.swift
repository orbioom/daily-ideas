import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \BreakLog.date, order: .reverse) private var breaks: [BreakLog]
    @Query(sort: \ExerciseSession.date, order: .reverse) private var sessions: [ExerciseSession]

    /// Anchor used for "time since last break" when there are no breaks yet (epoch seconds).
    @AppStorage("breakReferenceStart") private var referenceStartEpoch: Double = 0

    @State private var showBreak = false
    @State private var showSettings = false
    @State private var startedRoutine: EyeRoutine?
    @State private var paywallReason: PaywallReason?

    private let stats = StatsEngine()

    private var scheduler: BreakScheduler {
        BreakScheduler(intervalSeconds: settings.breakIntervalSeconds, dailyGoal: settings.dailyBreakGoal)
    }

    private var referenceStart: Date {
        referenceStartEpoch > 0 ? Date(timeIntervalSince1970: referenceStartEpoch) : .now
    }

    private var lastBreak: Date? { stats.mostRecentBreak(breaks) }
    private var breaksToday: Int { stats.breaksToday(breaks) }
    private var streak: Int { stats.currentStreak(breaks) }
    private var recommended: EyeRoutine { RoutineCatalog.recommended() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    breakRingCard
                    goalAndStreakRow
                    if settings.exerciseReminderEnabled { recommendedCard }
                    recentActivity
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").accessibilityLabel("Settings")
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .fullScreenCover(isPresented: $showBreak) {
                BreakView { logBreak() }
            }
            .fullScreenCover(item: $startedRoutine) { routine in
                RoutinePlayerView(routine: routine) { secs, count in
                    logSession(routine: routine, seconds: secs, count: count)
                }
            }
            .onAppear { ensureReferenceStart() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { ensureReferenceStart() }
            }
        }
    }

    // MARK: - Break ring (live)

    private var breakRingCard: some View {
        TimelineView(.periodic(from: .now, by: reduceMotion ? 1.0 : 0.5)) { context in
            let now = context.date
            let progress = scheduler.progress(lastBreak: lastBreak, referenceStart: referenceStart, now: now)
            let due = scheduler.isBreakDue(lastBreak: lastBreak, referenceStart: referenceStart, now: now)
            let label = scheduler.dueLabel(lastBreak: lastBreak, referenceStart: referenceStart, now: now)

            VStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: progress, lineWidth: 16)
                        .frame(width: 188, height: 188)
                    VStack(spacing: 4) {
                        Image(systemName: due ? "eye.fill" : "eye")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(due ? Theme.accent : Theme.inkSoft)
                            .accessibilityHidden(true)
                        Text(due ? "Time to rest" : "Keep going")
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(label)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Eye break timer")
                .accessibilityValue(label)

                PrimaryButton(title: "Take a 20-20-20 break", systemImage: "eye") {
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    showBreak = true
                }
            }
            .padding(20)
            .cardSurface()
        }
    }

    private var goalAndStreakRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(breaksToday)/\(settings.dailyBreakGoal)",
                     label: "Breaks today",
                     systemImage: "checkmark.circle.fill",
                     tint: scheduler.goalMet(breaksToday: breaksToday) ? Theme.good : Theme.accent)
            StatTile(value: streak > 0 ? "\(streak)" : "—",
                     label: "Day streak",
                     systemImage: "flame.fill",
                     tint: Theme.teal)
        }
    }

    private var recommendedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's routine", systemImage: "figure.mind.and.body")
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.accentSoft)
                        .frame(width: 52, height: 52)
                    Image(systemName: recommended.category.symbol)
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(recommended.name).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                    Text(recommended.summary)
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(recommended.totalMinutesLabel)
                        .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkFaint)
                }
                Spacer(minLength: 0)
            }
            Button {
                if RoutineCatalog.isFree(recommended) || isPro {
                    startedRoutine = recommended
                } else {
                    paywallReason = .routineLocked
                }
            } label: {
                HStack {
                    Text(RoutineCatalog.isFree(recommended) || isPro ? "Start routine" : "Unlock & start")
                        .font(Theme.rounded(15, .semibold))
                    if !(RoutineCatalog.isFree(recommended) || isPro) { ProLockChip() }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Theme.accent)
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent activity", systemImage: "clock.arrow.circlepath")
            if breaks.isEmpty {
                EmptyStateView(
                    symbol: "eye.slash",
                    title: "No breaks yet",
                    message: "Take your first 20-20-20 break and it'll show up here. Your eyes will thank you."
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(breaks.prefix(6))) { log in
                        ActivityRow(log: log)
                    }
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    // MARK: - Actions

    private func ensureReferenceStart() {
        if referenceStartEpoch <= 0 {
            referenceStartEpoch = Date.now.timeIntervalSince1970
        }
    }

    private func logBreak() {
        let log = BreakLog(date: .now, kind: .twentyRule, durationSeconds: 20, completed: true)
        modelContext.insert(log)
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func logSession(routine: EyeRoutine, seconds: Int, count: Int) {
        let session = ExerciseSession(date: .now,
                                      routineName: routine.name,
                                      durationSeconds: seconds,
                                      exercisesCompleted: count)
        modelContext.insert(session)
        modelContext.insert(BreakLog(date: .now, kind: .exercise, durationSeconds: seconds, completed: true))
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
    }
}

/// One row in the recent-activity feed.
private struct ActivityRow: View {
    let log: BreakLog

    private var timeText: String {
        log.date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 38, height: 38)
                Image(systemName: log.kind.symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(log.kind.label).font(Theme.rounded(15, .medium)).foregroundStyle(Theme.ink)
                Text(timeText).font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            Text("\(log.durationSeconds)s")
                .font(Theme.mono(13, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.kind.label), \(timeText), \(log.durationSeconds) seconds")
    }
}
