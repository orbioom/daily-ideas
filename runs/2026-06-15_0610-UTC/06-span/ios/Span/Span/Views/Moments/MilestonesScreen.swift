import SwiftUI
import SwiftData

/// Past milestones (pinned to weeks) and future goals with live countdowns.
struct MilestonesScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \LifeMilestone.date, order: .reverse) private var milestones: [LifeMilestone]
    @Query(sort: \FutureGoal.targetDate) private var goals: [FutureGoal]
    @Query private var profiles: [LifeProfile]

    @State private var editingMilestone: LifeMilestone?
    @State private var editingGoal: FutureGoal?
    @State private var showNewMilestone = false
    @State private var showNewGoal = false
    @State private var paywallReason: PaywallReason?

    private var profile: LifeProfile? { profiles.first }
    private var palette: Palette { settings.palette(isPro: isPro) }

    var body: some View {
        NavigationStack {
            Group {
                if milestones.isEmpty && goals.isEmpty {
                    EmptyStateView(symbol: "mappin.and.ellipse",
                                   title: "No moments yet",
                                   message: "Pin the milestones behind you and the goals ahead. Future goals get a live countdown.",
                                   actionTitle: "Add a milestone") {
                        attemptAddMilestone()
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    list
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Moments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            attemptAddMilestone()
                        } label: {
                            Label("New milestone", systemImage: "mappin")
                        }
                        Button {
                            attemptAddGoal()
                        } label: {
                            Label("New future goal", systemImage: "hourglass")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add")
                }
            }
            .sheet(isPresented: $showNewMilestone) {
                MilestoneEditorView(milestone: nil, palette: palette)
            }
            .sheet(item: $editingMilestone) { m in
                MilestoneEditorView(milestone: m, palette: palette)
            }
            .sheet(isPresented: $showNewGoal) {
                GoalEditorView(goal: nil, palette: palette)
            }
            .sheet(item: $editingGoal) { g in
                GoalEditorView(goal: g, palette: palette)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var list: some View {
        List {
            goalsSection
            milestonesSection
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
    }

    @ViewBuilder
    private var goalsSection: some View {
        Section {
            if goals.isEmpty {
                Button {
                    attemptAddGoal()
                } label: {
                    Label("Add a future goal", systemImage: "plus.circle")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.accent)
                }
                .listRowBackground(Theme.surface)
            } else {
                ForEach(goals) { goal in
                    Button { editingGoal = goal } label: {
                        GoalRow(goal: goal)
                    }
                    .listRowBackground(Theme.surface)
                }
                .onDelete(perform: deleteGoals)
            }
        } header: {
            Text("Counting down")
        } footer: {
            if !isPro {
                Text("Free plan: \(goals.count) of \(Pro.freeGoalLimit) goals used.")
            }
        }
    }

    @ViewBuilder
    private var milestonesSection: some View {
        Section {
            if milestones.isEmpty {
                Button {
                    attemptAddMilestone()
                } label: {
                    Label("Add a milestone", systemImage: "plus.circle")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.accent)
                }
                .listRowBackground(Theme.surface)
            } else {
                ForEach(milestones) { m in
                    Button { editingMilestone = m } label: {
                        MilestoneRow(milestone: m, profile: profile)
                    }
                    .listRowBackground(Theme.surface)
                }
                .onDelete(perform: deleteMilestones)
            }
        } header: {
            Text("Already lived")
        } footer: {
            if !isPro {
                Text("Free plan: \(milestones.count) of \(Pro.freeMilestoneLimit) milestones used.")
            }
        }
    }

    // MARK: Add gates

    private func attemptAddMilestone() {
        if Pro.canAddMilestone(count: milestones.count, isPro: isPro) {
            showNewMilestone = true
        } else {
            paywallReason = .milestones
        }
    }

    private func attemptAddGoal() {
        if Pro.canAddGoal(count: goals.count, isPro: isPro) {
            showNewGoal = true
        } else {
            paywallReason = .goals
        }
    }

    // MARK: Delete

    private func deleteMilestones(_ offsets: IndexSet) {
        for i in offsets where milestones.indices.contains(i) {
            context.delete(milestones[i])
        }
        try? context.save()
        Haptics.light(settings.hapticsEnabled)
    }

    private func deleteGoals(_ offsets: IndexSet) {
        for i in offsets where goals.indices.contains(i) {
            context.delete(goals[i])
        }
        try? context.save()
        Haptics.light(settings.hapticsEnabled)
    }
}

/// A milestone row with its symbol, title, date, and the age it happened at.
struct MilestoneRow: View {
    let milestone: LifeMilestone
    let profile: LifeProfile?

    private var color: Color { Color(hexString: milestone.colorHex, fallback: Theme.accent) }

    private var ageText: String? {
        guard let profile, milestone.date >= profile.birthDate else { return nil }
        let comps = Calendar(identifier: .gregorian)
            .dateComponents([.year], from: profile.birthDate, to: milestone.date)
        let y = max(comps.year ?? 0, 0)
        return "at \(y)"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: milestone.symbolName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(color))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    Text(Fmt.mediumDate.string(from: milestone.date))
                    if let ageText {
                        Text("·"); Text(ageText)
                    }
                }
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
