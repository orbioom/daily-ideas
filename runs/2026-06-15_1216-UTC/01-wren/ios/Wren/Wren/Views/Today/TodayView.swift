import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var companions: [Companion]
    @Query(filter: #Predicate<SelfCareGoal> { !$0.isArchived }, sort: \SelfCareGoal.createdAt)
    private var activeGoals: [SelfCareGoal]
    @Query(sort: \GoalCompletion.date) private var allCompletions: [GoalCompletion]

    @State private var toast: RewardToast?
    @State private var errorMessage: String?
    @State private var showLevelUp: Int?

    private var companion: Companion? { companions.first }

    private var dueToday: [SelfCareGoal] {
        activeGoals.filter { $0.isDue(on: Date()) }
    }

    private var completedTodayCount: Int {
        dueToday.filter { $0.isCompleted(on: Date()) }.count
    }

    private var completionDays: Set<Date> {
        Set(allCompletions.map { DateUtils.startOfDay($0.date) })
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        if let companion {
                            companionScene(companion)
                            checklistSection(companion)
                        } else {
                            EmptyStateView(
                                systemImage: "bird.fill",
                                title: "Setting up your companion",
                                message: "Your Wren is getting comfortable. Pull down or revisit in a moment."
                            )
                            .padding(.top, 60)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 90)
                }

                if let toast {
                    RewardToastView(toast: toast)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                }
            }
            .alert("Something went sideways", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: Companion scene

    private func companionScene(_ companion: Companion) -> some View {
        let energy = CareEngine.decayedEnergy(current: companion.energy, lastTendedAt: companion.lastTendedAt)
        let rate = CareEngine.completionRate(completionDays: completionDays)
        let mood = CareEngine.mood(completionRate7d: rate, energy: energy)
        let levelInfo = CareEngine.levelProgress(totalXP: companion.xp)

        return VStack(spacing: 14) {
            // Energy ring wrapping the bird
            ZStack {
                ProgressRing(fraction: Double(energy) / 100, lineWidth: 8, tint: mood.color)
                    .frame(width: 210, height: 210)
                WrenBirdView(mood: mood, accessory: companion.equippedAccessory)
                    .frame(width: 150, height: 150)
            }
            .padding(.top, 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(companion.name), \(mood.rawValue). Energy \(energy) of 100.")

            // Mood line
            HStack(spacing: 8) {
                Image(systemName: mood.systemImage)
                    .foregroundStyle(mood.color)
                Text(CareEngine.moodLine(mood, name: companion.name))
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)

            // Level + daily ring
            HStack(spacing: 12) {
                levelCard(levelInfo)
                dailyRingCard
            }
        }
        .padding(.vertical, 8)
    }

    private func levelCard(_ info: (level: Int, xpInto: Int, xpNeeded: Int)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Level \(info.level)")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if let companion { PebbleBadge(count: companion.pebbles) }
            }
            ProgressView(value: Double(info.xpInto), total: Double(max(1, info.xpNeeded)))
                .tint(Theme.accent)
            Text("\(info.xpInto) / \(info.xpNeeded) XP")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .card(Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(info.level). \(info.xpInto) of \(info.xpNeeded) experience.")
    }

    private var dailyRingCard: some View {
        let target = settings.dailyGoalTarget
        let fraction = CareEngine.dailyProgressFraction(completedToday: completedTodayCount, target: target)
        return VStack(spacing: 8) {
            ZStack {
                ProgressRing(fraction: fraction, lineWidth: 8, tint: Theme.good)
                    .frame(width: 56, height: 56)
                Text("\(completedTodayCount)")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
            }
            Text("\(completedTodayCount) of \(target) today")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .card(Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily goal: \(completedTodayCount) of \(target) completed.")
    }

    // MARK: Checklist

    private func checklistSection(_ companion: Companion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Today's care", subtitle: dueToday.isEmpty ? nil : "Tap to tend — your Wren feels each one.")

            if dueToday.isEmpty {
                EmptyStateView(
                    systemImage: "checklist",
                    title: "Nothing due today",
                    message: activeGoals.isEmpty
                        ? "Add a self-care goal in the Goals tab to begin."
                        : "Enjoy the quiet. Your scheduled goals will appear here on their days."
                )
                .card(Theme.surface)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(dueToday) { goal in
                        TodayGoalRow(
                            goal: goal,
                            isDone: goal.isCompleted(on: Date()),
                            onToggle: { toggle(goal, companion: companion) }
                        )
                    }
                }
            }
        }
    }

    // MARK: Actions

    private func toggle(_ goal: SelfCareGoal, companion: Companion) {
        let store = CareStore(context: modelContext)
        let alreadyDone = goal.isCompleted(on: Date())
        do {
            if alreadyDone {
                try store.uncompleteGoal(goal, companion: companion)
                settings.haptic(.soft)
            } else {
                let result = try store.completeGoal(goal, companion: companion)
                settings.haptic(.success)
                presentToast(result, goal: goal)
            }
        } catch let error as CareStore.StoreError {
            errorMessage = error.errorDescription
            settings.haptic(.warning)
        } catch {
            errorMessage = "Couldn't save your change. Please try again."
        }
    }

    private func presentToast(_ result: CareStore.CompletionResult, goal: SelfCareGoal) {
        let message: String?
        if let journey = result.journeyCompleted {
            message = "Journey complete — \(journey.rewardName) earned!"
        } else if let level = result.leveledUpTo {
            message = "Level \(level) reached!"
        } else {
            message = nil
        }
        let new = RewardToast(pebbles: result.pebbles, energy: result.energy, message: message)
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
            toast = new
        }
        // Auto-dismiss.
        let id = new.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toast?.id == id {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { toast = nil }
            }
        }
    }
}

// MARK: - Goal row

private struct TodayGoalRow: View {
    let goal: SelfCareGoal
    let isDone: Bool
    let onToggle: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isDone ? goal.category.color : Theme.hairline, lineWidth: 2)
                        .frame(width: 30, height: 30)
                    if isDone {
                        Circle()
                            .fill(goal.category.color)
                            .frame(width: 30, height: 30)
                            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: isDone)

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(isDone ? Theme.inkSoft : Theme.ink)
                        .strikethrough(isDone, color: Theme.inkSoft)
                    HStack(spacing: 8) {
                        CategoryChip(category: goal.category, compact: true)
                        Label("+\(goal.pebbleReward)", systemImage: "circle.grid.2x2.fill")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.warn)
                        Label("+\(goal.energyReward)", systemImage: "bolt.fill")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.good)
                    }
                }
                Spacer()
            }
            .padding(14)
            .card(isDone ? Theme.surfaceAlt : Theme.surface)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(goal.title)
        .accessibilityValue(isDone ? "Done" : "Not done")
        .accessibilityHint(isDone ? "Double-tap to undo" : "Double-tap to complete and reward your Wren")
        .accessibilityAddTraits(isDone ? [.isButton, .isSelected] : .isButton)
    }
}
