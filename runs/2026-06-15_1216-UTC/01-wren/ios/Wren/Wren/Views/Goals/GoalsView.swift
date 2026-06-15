import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \SelfCareGoal.createdAt) private var allGoals: [SelfCareGoal]

    @State private var editingGoal: SelfCareGoal?
    @State private var showingNew = false
    @State private var showPaywall = false
    @State private var showArchived = false
    @State private var errorMessage: String?

    private var activeGoals: [SelfCareGoal] { allGoals.filter { !$0.isArchived } }
    private var archivedGoals: [SelfCareGoal] { allGoals.filter { $0.isArchived } }

    private var grouped: [(category: GoalCategory, goals: [SelfCareGoal])] {
        GoalCategory.allCases.compactMap { cat in
            let goals = activeGoals.filter { $0.category == cat }
            return goals.isEmpty ? nil : (cat, goals)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if activeGoals.isEmpty && archivedGoals.isEmpty {
                    EmptyStateView(
                        systemImage: "checklist",
                        title: "No goals yet",
                        message: "Create gentle self-care goals across the things that matter to you.",
                        actionTitle: "Add a goal",
                        action: { attemptAdd() }
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .accessibilityLabel("Add goal")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                GoalEditorView(goal: nil)
            }
            .sheet(item: $editingGoal) { goal in
                GoalEditorView(goal: goal)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .goalLimit)
            }
            .alert("Couldn't update", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                limitBanner

                ForEach(grouped, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            CategoryChip(category: group.category)
                            Spacer()
                            Text("\(group.goals.count)")
                                .font(Theme.rounded(13, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        ForEach(group.goals) { goal in
                            GoalRow(goal: goal,
                                    onEdit: { editingGoal = goal },
                                    onArchive: { archive(goal, archived: true) },
                                    onDelete: { delete(goal) })
                        }
                    }
                }

                if !archivedGoals.isEmpty {
                    archivedSection
                }
            }
            .padding()
        }
    }

    private var limitBanner: some View {
        Group {
            if !settings.isPro {
                HStack(spacing: 10) {
                    Image(systemName: "leaf.fill").foregroundStyle(Theme.good)
                    Text("\(activeGoals.count) of \(Pro.freeActiveGoalLimit) free goals")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Button("Unlock more") { showPaywall = true }
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(12)
                .card(Theme.surfaceAlt)
            }
        }
    }

    private var archivedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation { showArchived.toggle() }
            } label: {
                HStack {
                    Text("Archived (\(archivedGoals.count))")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .buttonStyle(.plain)

            if showArchived {
                ForEach(archivedGoals) { goal in
                    GoalRow(goal: goal,
                            onEdit: { editingGoal = goal },
                            onArchive: { archive(goal, archived: false) },
                            onDelete: { delete(goal) },
                            isArchived: true)
                }
            }
        }
        .padding(.top, 6)
    }

    // MARK: Actions

    private func attemptAdd() {
        if Pro.canAddGoal(activeCount: activeGoals.count, isPro: settings.isPro) {
            showingNew = true
        } else {
            settings.haptic(.warning)
            showPaywall = true
        }
    }

    private func archive(_ goal: SelfCareGoal, archived: Bool) {
        // Restoring counts toward the free limit.
        if archived == false, !Pro.canAddGoal(activeCount: activeGoals.count, isPro: settings.isPro) {
            settings.haptic(.warning)
            showPaywall = true
            return
        }
        goal.isArchived = archived
        do { try modelContext.save() ; settings.haptic(.soft) }
        catch { errorMessage = "Couldn't update that goal." }
    }

    private func delete(_ goal: SelfCareGoal) {
        do {
            try CareStore(context: modelContext).deleteGoal(goal)
            settings.haptic(.soft)
        } catch {
            errorMessage = "Couldn't delete that goal."
        }
    }
}

// MARK: - Goal row

private struct GoalRow: View {
    let goal: SelfCareGoal
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    var isArchived: Bool = false

    @State private var confirmDelete = false

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    HStack(spacing: 8) {
                        Text(goal.schedule.summary)
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                        if !isArchived && goal.isDue(on: Date()) {
                            Text("Due today")
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Capsule().fill(Theme.accentSoft))
                        }
                    }
                    HStack(spacing: 10) {
                        Label("+\(goal.pebbleReward)", systemImage: "circle.grid.2x2.fill")
                            .foregroundStyle(Theme.warn)
                        Label("+\(goal.energyReward)", systemImage: "bolt.fill")
                            .foregroundStyle(Theme.good)
                    }
                    .font(Theme.rounded(11, .semibold))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(14)
            .opacity(isArchived ? 0.6 : 1)
            .card(Theme.surface)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { confirmDelete = true } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { onArchive() } label: {
                Label(isArchived ? "Restore" : "Archive", systemImage: isArchived ? "tray.and.arrow.up" : "archivebox")
            }
            .tint(Theme.inkSoft)
        }
        .alert("Delete this goal?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This also removes its completion history.")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(goal.title)
        .accessibilityValue("\(goal.category.label), \(goal.schedule.summary)")
        .accessibilityHint("Double-tap to edit")
    }
}
