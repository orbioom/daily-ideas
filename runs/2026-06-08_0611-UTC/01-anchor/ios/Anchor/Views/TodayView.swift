import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.order) private var allHabits: [Habit]
    @Query private var allEntries: [HabitEntry]

    @State private var calendar = Calendar.current
    @State private var selectedHabit: Habit?
    @State private var showDetail = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var today: Date { calendar.startOfDay(for: .now) }

    private var scheduledHabits: [Habit] {
        allHabits.filter {
            !$0.archived && StreakEngine.isScheduled($0, on: today, calendar: calendar)
        }
    }

    private var completedCount: Int {
        scheduledHabits.filter {
            StreakEngine.isComplete($0, on: today, entries: allEntries, calendar: calendar)
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if scheduledHabits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .navigationTitle(Format.dayFull.string(from: today))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Format.dayFull.string(from: today))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let habit = selectedHabit {
                    HabitDetailView(habit: habit)
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        EmptyStateView(
            icon: "checkmark.seal",
            title: "Nothing Scheduled",
            message: "No habits are set for today. Add a habit in the Habits tab to get started."
        )
        .padding(.horizontal, 24)
    }

    private var habitList: some View {
        ScrollView {
            VStack(spacing: 20) {
                ringHeader

                LazyVStack(spacing: 10) {
                    ForEach(scheduledHabits) { habit in
                        TodayHabitRow(
                            habit: habit,
                            entries: allEntries,
                            today: today,
                            calendar: calendar,
                            onTap: {
                                selectedHabit = habit
                                showDetail = true
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.top, 16)
        }
    }

    private var ringHeader: some View {
        VStack(spacing: 8) {
            LargeRingProgress(
                completed: completedCount,
                total: scheduledHabits.count,
                color: Brand.live
            )

            let allDone = completedCount == scheduledHabits.count
            Text(allDone ? "All done for today!" : "\(scheduledHabits.count - completedCount) remaining")
                .font(.subheadline)
                .foregroundStyle(allDone ? Brand.live : Brand.text2)
                .animation(reduceMotion ? .none : Brand.ease(0.3), value: completedCount)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(completedCount) of \(scheduledHabits.count) habits completed today")
    }
}

// MARK: - Today Habit Row

struct TodayHabitRow: View {
    let habit: Habit
    let entries: [HabitEntry]
    let today: Date
    let calendar: Calendar
    let onTap: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var habitColor: Color { Color(hex: habit.colorHex) }
    private var currentCount: Int {
        StreakEngine.count(for: habit, on: today, entries: entries, calendar: calendar)
    }
    private var isComplete: Bool {
        StreakEngine.isComplete(habit, on: today, entries: entries, calendar: calendar)
    }
    private var progress: Double {
        guard habit.dailyTarget > 0 else { return 0 }
        return Double(currentCount) / Double(habit.dailyTarget)
    }
    private var streak: Int {
        StreakEngine.currentStreak(habit, entries: entries, asOf: today, calendar: calendar)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Symbol + Ring
            ZStack {
                RingProgress(
                    progress: progress,
                    color: habitColor,
                    lineWidth: 3,
                    size: 48,
                    showCheckmark: isComplete
                )
                if !isComplete {
                    Image(systemName: habit.symbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(habitColor)
                        .accessibilityHidden(true)
                }
            }

            // Name + streak
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if streak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(Brand.warn)
                            .accessibilityHidden(true)
                        Text(habit.scheduleType == .timesPerWeek
                             ? Format.weeksStreakText(streak)
                             : Format.streakText(streak))
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    } else {
                        Text(habit.polarity == .quit ? "Stay clean today" : "Start your streak")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
            }

            Spacer()

            // Progress indicator / stepper
            if habit.dailyTarget > 1 {
                stepperButton
            } else {
                tapButton
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isComplete ? habitColor.opacity(0.4) : Brand.glassStroke.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Brand.cardShadow, radius: 8, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { onTap() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double-tap to view detail")
    }

    private var accessibilityLabel: String {
        var parts = [habit.name]
        if habit.dailyTarget > 1 {
            parts.append("\(currentCount) of \(habit.dailyTarget) \(habit.unit.isEmpty ? "times" : habit.unit)")
        } else {
            parts.append(isComplete ? "Complete" : "Not done")
        }
        if streak > 0 {
            parts.append("Streak: \(streak)")
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Single-tap complete button

    private var tapButton: some View {
        Button {
            toggleCompletion()
        } label: {
            ZStack {
                Circle()
                    .fill(isComplete ? habitColor : Color.clear)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().strokeBorder(habitColor.opacity(0.5), lineWidth: 1.5))

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
            }
            .animation(reduceMotion ? .none : Brand.ease(0.25), value: isComplete)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isComplete ? "Mark incomplete" : "Mark complete")
    }

    // MARK: - Multi-step stepper button

    private var stepperButton: some View {
        HStack(spacing: 8) {
            Text("\(currentCount)/\(habit.dailyTarget)")
                .font(Brand.mono(13, weight: .medium))
                .foregroundStyle(isComplete ? habitColor : Brand.text2)
                .frame(minWidth: 40)

            Button {
                addCount()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(habitColor)
                    .accessibilityHidden(true)
            }
            .buttonStyle(.plain)
            .disabled(isComplete)
            .accessibilityLabel("Add \(habit.unit.isEmpty ? "one" : "one \(habit.unit)")")
        }
    }

    // MARK: - Actions

    private func toggleCompletion() {
        let wasComplete = isComplete
        if wasComplete {
            removeLastEntry()
            Haptics.tap()
        } else {
            addEntry(count: habit.dailyTarget)
            Haptics.success()
        }
    }

    private func addCount() {
        if let existing = existingEntry(for: today) {
            existing.count += 1
            if existing.count >= habit.dailyTarget {
                Haptics.success()
            } else {
                Haptics.tap()
            }
        } else {
            addEntry(count: 1)
            Haptics.tap()
        }
    }

    private func existingEntry(for day: Date) -> HabitEntry? {
        let start = calendar.startOfDay(for: day)
        return entries.first {
            $0.habit?.id == habit.id && calendar.startOfDay(for: $0.day) == start
        }
    }

    private func addEntry(count: Int) {
        let entry = HabitEntry(day: today, count: count, habit: habit)
        context.insert(entry)
        habit.entries.append(entry)
    }

    private func removeLastEntry() {
        let start = calendar.startOfDay(for: today)
        let toRemove = entries.filter {
            $0.habit?.id == habit.id && calendar.startOfDay(for: $0.day) == start
        }
        for entry in toRemove {
            context.delete(entry)
        }
    }
}
