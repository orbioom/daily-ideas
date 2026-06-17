import SwiftUI
import SwiftData

/// Tab 1 — all goals as cards, sorted by priority then progress.
struct GoalsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Query(sort: \Goal.createdAt, order: .reverse) private var allGoals: [Goal]

    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var showArchived = false

    private var activeGoals: [Goal] {
        allGoals.filter { !$0.isArchived }.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            let l = GoalEngine.summary(for: lhs).progressFraction
            let r = GoalEngine.summary(for: rhs).progressFraction
            return l > r
        }
    }

    private var archivedGoals: [Goal] {
        allGoals.filter { $0.isArchived }
    }

    private var atFreeLimit: Bool {
        !pro.isPro && activeGoals.count >= ProStore.freeGoalLimit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addTapped()
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add goal")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                GoalEditorView(mode: .create)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if activeGoals.isEmpty && archivedGoals.isEmpty {
            EmptyStateView(
                symbol: "target",
                title: "Start your first nest",
                message: "Create a savings goal — a target amount and a date — and Nest will pace it for you.",
                actionTitle: "Create a goal",
                action: { addTapped() }
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    summaryHeader

                    ForEach(activeGoals) { goal in
                        NavigationLink {
                            GoalDetailView(goal: goal)
                        } label: {
                            GoalCard(goal: goal, settings: settings)
                        }
                        .buttonStyle(.plain)
                    }

                    if atFreeLimit {
                        upgradeHint
                    }

                    if !archivedGoals.isEmpty {
                        archivedSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private var summaryHeader: some View {
        let totalSaved = activeGoals.reduce(Decimal(0)) { $0 + GoalEngine.savedAmount($1) }
        let totalTarget = activeGoals.reduce(Decimal(0)) { $0 + Decimal($1.targetAmount) }
        let fraction = totalTarget > 0
            ? min(max((totalSaved as NSDecimalNumber).doubleValue / (totalTarget as NSDecimalNumber).doubleValue, 0), 1)
            : 0
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Total saved")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Text(settings.displayDecimal(totalSaved))
                    .font(Theme.money(30, .bold))
                    .foregroundStyle(Theme.ink)
                ProgressView(value: fraction)
                    .tint(Theme.accent)
                    .accessibilityHidden(true)
                Text("of \(settings.displayDecimal(totalTarget)) across \(activeGoals.count) goal\(activeGoals.count == 1 ? "" : "s")")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var upgradeHint: some View {
        Button {
            showingPaywall = true
        } label: {
            Card {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("You've reached the free limit")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Unlock Nest Pro for unlimited goals.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var archivedSection: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation { showArchived.toggle() }
            } label: {
                HStack {
                    Text("Archived (\(archivedGoals.count))")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            if showArchived {
                ForEach(archivedGoals) { goal in
                    NavigationLink {
                        GoalDetailView(goal: goal)
                    } label: {
                        GoalCard(goal: goal, settings: settings)
                            .opacity(0.7)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addTapped() {
        if atFreeLimit {
            showingPaywall = true
        } else {
            showingAdd = true
        }
    }
}
