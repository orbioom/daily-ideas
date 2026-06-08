import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.order) private var habits: [Habit]
    @AppStorage("anchor.showArchived") private var showArchived = false

    @State private var showAdd = false
    @State private var habitToEdit: Habit?
    @State private var habitToDelete: Habit?
    @State private var showDeleteConfirm = false
    @State private var calendar = Calendar.current

    private var activeHabits: [Habit] {
        habits.filter { !$0.archived }
    }
    private var archivedHabits: [Habit] {
        habits.filter { $0.archived }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if habits.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.circle",
                        title: "No Habits Yet",
                        message: "Tap the + button to create your first habit and start building momentum."
                    )
                    .padding(.horizontal, 24)
                } else {
                    habitList
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                        Haptics.tap()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Add new habit")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEditHabitView(editingHabit: nil)
            }
            .sheet(item: $habitToEdit) { habit in
                AddEditHabitView(editingHabit: habit)
            }
            .confirmationDialog(
                "Delete \"\(habitToDelete?.name ?? "")\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let h = habitToDelete {
                        deleteHabit(h)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All entries for this habit will be permanently removed.")
            }
        }
    }

    // MARK: - List

    private var habitList: some View {
        List {
            Section {
                ForEach(activeHabits) { habit in
                    NavigationLink {
                        HabitDetailView(habit: habit)
                    } label: {
                        HabitListRow(habit: habit, calendar: calendar)
                    }
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            habitToDelete = habit
                            showDeleteConfirm = true
                            Haptics.warning()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            habitToEdit = habit
                            Haptics.tap()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Brand.info)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            habit.archived = true
                            Haptics.selection()
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(Brand.warn)
                    }
                }
                .onMove(perform: moveActive)
            } header: {
                Eyebrow(text: "Active (\(activeHabits.count))")
                    .padding(.leading, -4)
            }

            if showArchived && !archivedHabits.isEmpty {
                Section {
                    ForEach(archivedHabits) { habit in
                        NavigationLink {
                            HabitDetailView(habit: habit)
                        } label: {
                            HabitListRow(habit: habit, calendar: calendar)
                                .opacity(0.6)
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                habitToDelete = habit
                                showDeleteConfirm = true
                                Haptics.warning()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                habit.archived = false
                                Haptics.selection()
                            } label: {
                                Label("Unarchive", systemImage: "tray.and.arrow.up")
                            }
                            .tint(Brand.live)
                        }
                    }
                } header: {
                    Eyebrow(text: "Archived (\(archivedHabits.count))")
                        .padding(.leading, -4)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.inactive))
    }

    // MARK: - Actions

    private func moveActive(from: IndexSet, to: Int) {
        var reordered = activeHabits
        reordered.move(fromOffsets: from, toOffset: to)
        for (idx, habit) in reordered.enumerated() {
            habit.order = idx
        }
    }

    private func deleteHabit(_ habit: Habit) {
        context.delete(habit)
        Haptics.success()
    }
}

// MARK: - Habit List Row

private struct HabitListRow: View {
    let habit: Habit
    let calendar: Calendar

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.colorHex).opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: habit.symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: habit.colorHex))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text(scheduleDescription)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }

            Spacer()

            if habit.polarity == .quit {
                Image(systemName: "minus.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Brand.danger)
                    .accessibilityLabel("Quit habit")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.name), \(scheduleDescription)\(habit.polarity == .quit ? ", quit habit" : "")")
    }

    private var scheduleDescription: String {
        switch habit.scheduleType {
        case .everyDay:     return "Every day"
        case .specificDays: return specificDaysText
        case .timesPerWeek: return "\(habit.timesPerWeekTarget)x per week"
        }
    }

    private var specificDaysText: String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let selected = (0..<7).filter { (habit.weekdayMask >> $0) & 1 == 1 }
            .compactMap { names[safe: $0] }
        if selected.count == 7 { return "Every day" }
        if selected.count == 0 { return "No days set" }
        return selected.joined(separator: ", ")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
