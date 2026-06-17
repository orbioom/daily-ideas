import SwiftUI
import SwiftData

/// Today's hub: current plan card, today's session, big Start button, week +
/// overall progress rings and the streak. Empty state when not enrolled.
struct HomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @Bindable var player: PlayerEngine
    @Binding var showPlayer: Bool

    @Query private var activePlans: [ActivePlan]
    @Query(sort: \CompletedSession.date, order: .reverse) private var completed: [CompletedSession]

    private var active: ActivePlan? { activePlans.first }
    private var plan: TrainingPlan? { active.flatMap { PlanResolver.shared.plan(id: $0.planId) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let active, let plan {
                    enrolledContent(active: active, plan: plan)
                } else {
                    notEnrolled
                }
            }
            .laceScreenBackground(scheme)
            .navigationTitle("Today")
        }
    }

    // MARK: - Enrolled

    @ViewBuilder
    private func enrolledContent(active: ActivePlan, plan: TrainingPlan) -> some View {
        let session = plan.session(week: active.currentWeek, index: active.currentSessionIndex)
        let planCompleted = completed.filter { $0.planId == plan.id }
        let overall = ProgressEngine.completionFraction(plan: plan, completed: planCompleted)
        let stats = ProgressEngine.stats(completed)

        VStack(spacing: 16) {
            // Greeting + plan
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText(scheme))
                Text(plan.title)
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.primaryText(scheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Today's session card
            if let session {
                todayCard(plan: plan, active: active, session: session)
            } else {
                planCompleteCard(plan: plan)
            }

            // Progress rings
            progressCard(plan: plan, active: active, overall: overall, weekDone: weekSessionsDone(plan: plan, active: active, completed: planCompleted))

            // Streak / quick stats
            LaceCard {
                HStack(spacing: 0) {
                    StatPill(value: "\(stats.currentStreakDays)", label: "Day streak", systemImage: "flame.fill")
                    Divider().frame(height: 36)
                    StatPill(value: "\(stats.sessionsThisWeek)", label: "This week", systemImage: "calendar")
                    Divider().frame(height: 36)
                    StatPill(value: "\(stats.totalSessions)", label: "Total runs", systemImage: "checkmark.seal.fill")
                }
            }
        }
        .padding(20)
    }

    private func todayCard(plan: TrainingPlan, active: ActivePlan, session: PlanSession) -> some View {
        LaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Week \(active.currentWeek) · Session \(active.currentSessionIndex + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Theme.coral))
                    Spacer()
                    Label(Fmt.minutes(session.totalSeconds), systemImage: "clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText(scheme))
                }

                Text(session.summary)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.primaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                IntervalStrip(intervals: session.intervals)
                IntervalLegend(kinds: presentKinds(session))

                Button {
                    startSession(plan: plan, session: session, week: active.currentWeek, index: active.currentSessionIndex)
                } label: {
                    Label("Start session", systemImage: "play.fill")
                }
                .buttonStyle(LacePrimaryButtonStyle())
                .accessibilityHint("Begins the guided run/walk player")

                NavigationLink {
                    SessionDetailView(plan: plan, session: session, week: active.currentWeek, index: active.currentSessionIndex,
                                      player: player, showPlayer: $showPlayer, isCompleted: false)
                } label: {
                    Text("View interval breakdown")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LaceSecondaryButtonStyle())
            }
        }
    }

    private func planCompleteCard(plan: TrainingPlan) -> some View {
        LaceCard {
            VStack(spacing: 10) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.positive)
                    .accessibilityHidden(true)
                Text("You finished \(plan.title)!")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.primaryText(scheme))
                    .multilineTextAlignment(.center)
                Text("Pick a new plan from the Plan tab to keep the momentum going.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func progressCard(plan: TrainingPlan, active: ActivePlan, overall: Double, weekDone: (done: Int, total: Int)) -> some View {
        let weekFraction = weekDone.total > 0 ? Double(weekDone.done) / Double(weekDone.total) : 0
        return LaceCard {
            HStack(spacing: 22) {
                ring(fraction: weekFraction, color: Theme.coral,
                     big: "\(weekDone.done)/\(weekDone.total)", caption: "Week \(active.currentWeek)")
                ring(fraction: overall, color: Theme.teal,
                     big: Fmt.percent(overall), caption: "Overall")
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(plan.totalSessions) sessions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.primaryText(scheme))
                    Text("\(plan.weekCount) weeks to 5K")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText(scheme))
                    Text(plan.weeks.first(where: { $0.weekNumber == active.currentWeek })?.focus ?? "")
                        .font(.caption)
                        .foregroundStyle(Theme.coral)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func ring(fraction: Double, color: Color, big: String, caption: String) -> some View {
        VStack(spacing: 6) {
            ProgressRing(progress: fraction, lineWidth: 9, color: color,
                centerContent: AnyView(
                    Text(big)
                        .font(Theme.numeral(16))
                        .foregroundStyle(Theme.primaryText(scheme))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                ))
                .frame(width: 70, height: 70)
            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText(scheme))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption) progress")
        .accessibilityValue("\(big)\(caption == "Overall" ? " complete" : " sessions done")")
    }

    // MARK: - Not enrolled

    private var notEnrolled: some View {
        VStack {
            EmptyStateView(
                icon: "figure.run",
                title: "Ready to start?",
                message: "Choose a training plan to get your first guided session.",
                actionTitle: nil,
                action: nil
            )
            NavigationLink {
                ChoosePlanView()
            } label: {
                Text("Choose a plan")
            }
            .buttonStyle(LacePrimaryButtonStyle())
            .padding(.horizontal, 44)
        }
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private func startSession(plan: TrainingPlan, session: PlanSession, week: Int, index: Int) {
        player.voiceCuesEnabled = settings.voiceCuesEnabled
        player.countdownBeepsEnabled = settings.countdownBeeps
        player.hapticsEnabled = settings.hapticCues
        player.start(plan: plan, session: session, week: week, sessionIndex: index)
        Haptics.medium(settings.hapticCues)
        showPlayer = true
    }

    private func presentKinds(_ session: PlanSession) -> [IntervalKind] {
        var seen: [IntervalKind] = []
        for i in session.intervals where !seen.contains(i.kind) { seen.append(i.kind) }
        return seen
    }

    private func weekSessionsDone(plan: TrainingPlan, active: ActivePlan, completed: [CompletedSession]) -> (done: Int, total: Int) {
        let total = plan.weeks.first(where: { $0.weekNumber == active.currentWeek })?.sessions.count ?? 0
        let done = Set(completed.filter { $0.week == active.currentWeek }.map { $0.sessionIndex }).count
        return (min(done, total), total)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
