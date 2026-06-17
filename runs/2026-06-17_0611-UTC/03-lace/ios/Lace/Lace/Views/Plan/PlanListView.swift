import SwiftUI
import SwiftData

/// The full week-by-week schedule for the active plan. Each session row shows
/// its structure and a completed badge; tap to view detail / start. Includes a
/// switch-plan entry and a Pro custom-builder entry.
struct PlanListView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(ProStore.self) private var pro

    @Bindable var player: PlayerEngine
    @Binding var showPlayer: Bool

    @Query private var activePlans: [ActivePlan]
    @Query private var completed: [CompletedSession]

    private var active: ActivePlan? { activePlans.first }
    private var plan: TrainingPlan? { active.flatMap { PlanResolver.shared.plan(id: $0.planId) } }

    var body: some View {
        NavigationStack {
            Group {
                if let active, let plan {
                    schedule(active: active, plan: plan)
                } else {
                    notEnrolled
                }
            }
            .laceScreenBackground(scheme)
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ChoosePlanView()
                    } label: {
                        Label("Switch plan", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }

    private func schedule(active: ActivePlan, plan: TrainingPlan) -> some View {
        let doneKeys = Set(completed.filter { $0.planId == plan.id }.map { "\($0.week)-\($0.sessionIndex)" })
        return ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                // Plan header
                LaceCard {
                    HStack(spacing: 14) {
                        Image(systemName: plan.symbol)
                            .font(.title.weight(.bold))
                            .foregroundStyle(Theme.coral)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.title).font(.title3.weight(.bold))
                                .foregroundStyle(Theme.primaryText(scheme))
                            Text(plan.subtitle).font(.subheadline)
                                .foregroundStyle(Theme.secondaryText(scheme))
                        }
                        Spacer(minLength: 0)
                    }
                }

                ForEach(plan.weeks) { week in
                    weekCard(week: week, active: active, plan: plan, doneKeys: doneKeys)
                }

                if pro.isPro {
                    NavigationLink {
                        CustomPlanListView()
                    } label: {
                        LaceCard {
                            Label("Custom plan builder", systemImage: "slider.horizontal.3")
                                .font(.headline)
                                .foregroundStyle(Theme.coral)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    private func weekCard(week: PlanWeek, active: ActivePlan, plan: TrainingPlan, doneKeys: Set<String>) -> some View {
        LaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Week \(week.weekNumber)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.primaryText(scheme))
                    Spacer()
                    Text(week.focus)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.coral)
                }
                ForEach(Array(week.sessions.enumerated()), id: \.element.id) { idx, session in
                    let isDone = doneKeys.contains("\(week.weekNumber)-\(idx)")
                    let isCurrent = active.currentWeek == week.weekNumber && active.currentSessionIndex == idx
                    NavigationLink {
                        SessionDetailView(plan: plan, session: session, week: week.weekNumber, index: idx,
                                          player: player, showPlayer: $showPlayer, isCompleted: isDone)
                    } label: {
                        sessionRow(idx: idx, session: session, isDone: isDone, isCurrent: isCurrent)
                    }
                    .buttonStyle(.plain)
                    if idx < week.sessions.count - 1 {
                        Divider().background(Theme.hairline(scheme))
                    }
                }
            }
        }
    }

    private func sessionRow(idx: Int, session: PlanSession, isDone: Bool, isCurrent: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isDone ? Theme.positive.opacity(0.18) : (isCurrent ? Theme.coral.opacity(0.18) : Theme.subtleSurface(scheme)))
                    .frame(width: 36, height: 36)
                Image(systemName: isDone ? "checkmark" : "\(idx + 1).circle")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isDone ? Theme.positive : (isCurrent ? Theme.coral : Theme.secondaryText(scheme)))
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Session \(idx + 1)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.primaryText(scheme))
                    if isCurrent {
                        Text("Next")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.coral))
                    }
                }
                Text(session.summary)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(Fmt.minutes(session.totalSeconds))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText(scheme))
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText(scheme))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Session \(idx + 1), \(session.summary)\(isDone ? ", completed" : "")\(isCurrent ? ", your next session" : "")")
    }

    private var notEnrolled: some View {
        ScrollView {
            VStack {
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    title: "No plan yet",
                    message: "Pick a training plan to see your full week-by-week schedule."
                )
                NavigationLink {
                    ChoosePlanView()
                } label: { Text("Choose a plan") }
                    .buttonStyle(LacePrimaryButtonStyle())
                    .padding(.horizontal, 44)
            }
            .padding(.top, 60)
        }
    }
}
