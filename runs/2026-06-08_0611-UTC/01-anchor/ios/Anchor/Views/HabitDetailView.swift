import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.modelContext) private var context
    @Query private var allEntries: [HabitEntry]

    @State private var showEdit = false
    @State private var calendar = Calendar.current

    private var entries: [HabitEntry] {
        allEntries.filter { $0.habit?.id == habit.id }
    }

    private var today: Date { calendar.startOfDay(for: .now) }
    private var currentStreak: Int {
        StreakEngine.currentStreak(habit, entries: entries, asOf: today, calendar: calendar)
    }
    private var longest: Int {
        StreakEngine.longestStreak(habit, entries: entries, calendar: calendar)
    }
    private var rate30: Double {
        StreakEngine.completionRate(habit, entries: entries, lastNDays: 30, calendar: calendar)
    }
    private var totalDone: Int {
        StreakEngine.totalCompletions(habit, entries: entries, calendar: calendar)
    }

    var body: some View {
        ZStack {
            Brand.pageBackground

            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    statsGrid
                    heatmapCard
                    recentEntriesCard
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEdit = true
                    Haptics.tap()
                } label: {
                    Image(systemName: "pencil")
                        .accessibilityLabel("Edit habit")
                }
                .foregroundStyle(Brand.text)
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditHabitView(editingHabit: habit)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.colorHex).opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: habit.symbol)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color(hex: habit.colorHex))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)

                HStack(spacing: 6) {
                    StatusDot(color: habit.archived ? Brand.text3 : Brand.live)
                    Text(habit.archived ? "Archived" : "Active")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)

                    Text("·")
                        .foregroundStyle(Brand.text3)

                    Text(habit.polarity == .build ? "Building" : "Quitting")
                        .font(.caption)
                        .foregroundStyle(habit.polarity == .build ? Brand.live : Brand.danger)
                }
            }
            Spacer()
        }
        .glassCard()
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCell(
                label: habit.scheduleType == .timesPerWeek ? "Week Streak" : "Current Streak",
                value: habit.scheduleType == .timesPerWeek
                    ? Format.weeksStreakText(currentStreak)
                    : Format.streakText(currentStreak),
                icon: "flame.fill",
                iconColor: Brand.warn
            )
            statCell(
                label: "Longest Streak",
                value: habit.scheduleType == .timesPerWeek
                    ? Format.weeksStreakText(longest)
                    : Format.streakText(longest),
                icon: "trophy.fill",
                iconColor: Color(hex: 0xE0B86A)
            )
            statCell(
                label: "30-Day Rate",
                value: Format.percent(rate30),
                icon: "chart.pie.fill",
                iconColor: Brand.info
            )
            statCell(
                label: "Total Completions",
                value: "\(totalDone)",
                icon: "checkmark.seal.fill",
                iconColor: Brand.live
            )
        }
    }

    private func statCell(label: String, value: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
                Eyebrow(text: label)
            }
            Text(value)
                .font(Brand.mono(22, weight: .bold))
                .foregroundStyle(Brand.text)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Mini heatmap

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "12-Week History")

            ContributionHeatmap(
                weeks: buildHeatmapData(),
                color: Color(hex: habit.colorHex),
                cellSize: 13,
                spacing: 4
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard()
    }

    private func buildHeatmapData() -> [[Double]] {
        let numWeeks = 12
        var result: [[Double]] = []
        for weekOffset in (0..<numWeeks).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: StreakEngine.startOfWeek(for: today, calendar: calendar)) else {
                result.append(Array(repeating: 0.0, count: 7))
                continue
            }
            var row: [Double] = []
            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    row.append(0)
                    continue
                }
                if day > today {
                    row.append(0)
                } else if StreakEngine.isComplete(habit, on: day, entries: entries, calendar: calendar) {
                    row.append(1.0)
                } else if StreakEngine.count(for: habit, on: day, entries: entries, calendar: calendar) > 0 {
                    row.append(0.5)
                } else {
                    row.append(0)
                }
            }
            result.append(row)
        }
        return result
    }

    // MARK: - Recent entries

    private var recentEntriesCard: some View {
        let sorted = entries
            .sorted { $0.day > $1.day }
            .prefix(14)

        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Recent Entries")

            if sorted.isEmpty {
                Text("No entries recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .padding(.top, 4)
            } else {
                ForEach(Array(sorted)) { entry in
                    HStack {
                        Text(Format.relativeDay(entry.day, relativeTo: today, calendar: calendar))
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)

                        Spacer()

                        let countLabel = habit.dailyTarget > 1
                            ? Format.unitLabel(count: entry.count, unit: habit.unit)
                            : (entry.count > 0 ? "Done" : "")
                        Text(countLabel)
                            .font(Brand.mono(14, weight: .medium))
                            .foregroundStyle(entry.count >= habit.dailyTarget ? Brand.live : Brand.text2)
                    }
                    .padding(.vertical, 2)

                    if entry.id != sorted.last?.id {
                        Divider()
                            .overlay(Brand.hairline)
                    }
                }
            }
        }
        .glassCard()
    }
}
