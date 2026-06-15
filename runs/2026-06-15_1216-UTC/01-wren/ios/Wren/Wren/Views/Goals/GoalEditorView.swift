import SwiftUI
import SwiftData

struct GoalEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    /// nil = create new.
    let goal: SelfCareGoal?

    @State private var title: String = ""
    @State private var category: GoalCategory = .move
    @State private var scheduleKind: ScheduleKind = .everyDay
    @State private var weekdays: Set<Int> = [2, 3, 4, 5, 6] // weekdays default
    @State private var timesPerWeek: Int = 3
    @State private var pebbleReward: Int = 5
    @State private var energyReward: Int = 8
    @State private var errorMessage: String?

    private var isEditing: Bool { goal != nil }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool {
        !trimmedTitle.isEmpty &&
        (scheduleKind != .specificDays || !weekdays.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What") {
                    TextField("Goal title", text: $title, axis: .vertical)
                        .font(Theme.rounded(16))
                        .accessibilityLabel("Goal title")
                    Picker("Category", selection: $category) {
                        ForEach(GoalCategory.allCases) { cat in
                            Label(cat.label, systemImage: cat.systemImage).tag(cat)
                        }
                    }
                }

                Section("Schedule") {
                    Picker("How often", selection: $scheduleKind) {
                        ForEach(ScheduleKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)

                    if scheduleKind == .specificDays {
                        weekdayPicker
                    } else if scheduleKind == .timesPerWeek {
                        Stepper(value: $timesPerWeek, in: 1...7) {
                            Text("\(timesPerWeek)× per week")
                                .font(Theme.rounded(15))
                        }
                        .accessibilityValue("\(timesPerWeek) times per week")
                    }
                }

                Section {
                    Stepper(value: $pebbleReward, in: 1...20) {
                        Label("\(pebbleReward) pebbles", systemImage: "circle.grid.2x2.fill")
                            .foregroundStyle(Theme.warn)
                    }
                    .accessibilityValue("\(pebbleReward) pebbles")
                    Stepper(value: $energyReward, in: 1...20) {
                        Label("\(energyReward) energy", systemImage: "bolt.fill")
                            .foregroundStyle(Theme.good)
                    }
                    .accessibilityValue("\(energyReward) energy")
                } header: {
                    Text("Reward for your Wren")
                } footer: {
                    Text("Completing this goal gives \(pebbleReward) pebbles to spend and \(energyReward) energy plus experience to \(companionName).")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .onAppear(perform: load)
        }
    }

    private var companionName: String {
        let companions = (try? modelContext.fetch(FetchDescriptor<Companion>())) ?? []
        return companions.first?.name ?? "your Wren"
    }

    private var weekdayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick days")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { wd in
                    let on = weekdays.contains(wd)
                    Button {
                        if on { weekdays.remove(wd) } else { weekdays.insert(wd) }
                    } label: {
                        Text(DateUtils.shortWeekdaySymbol(forWeekday: wd).prefix(1))
                            .font(Theme.rounded(13, .semibold))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(on ? Theme.accent : Theme.surfaceAlt))
                            .foregroundStyle(on ? .white : Theme.inkSoft)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(DateUtils.shortWeekdaySymbol(forWeekday: wd))
                    .accessibilityValue(on ? "Selected" : "Not selected")
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Load / Save

    private func load() {
        guard let goal else { return }
        title = goal.title
        category = goal.category
        pebbleReward = goal.pebbleReward
        energyReward = goal.energyReward
        switch goal.schedule {
        case .everyDay:
            scheduleKind = .everyDay
        case .specificDays(let mask):
            scheduleKind = .specificDays
            weekdays = Set((1...7).filter { ((mask >> ($0 - 1)) & 1) == 1 })
        case .timesPerWeek(let n):
            scheduleKind = .timesPerWeek
            timesPerWeek = n
        }
    }

    private func buildSchedule() -> GoalSchedule {
        switch scheduleKind {
        case .everyDay:
            return .everyDay
        case .specificDays:
            let mask = weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
            return .specificDays(mask: mask)
        case .timesPerWeek:
            return .timesPerWeek(max(1, timesPerWeek))
        }
    }

    private func save() {
        guard isValid else { return }
        let schedule = buildSchedule()
        if let goal {
            goal.title = trimmedTitle
            goal.categoryRaw = category.rawValue
            goal.pebbleReward = pebbleReward
            goal.energyReward = energyReward
            switch schedule {
            case .everyDay:
                goal.scheduleKindRaw = ScheduleKind.everyDay.rawValue
                goal.weekdayMask = 0; goal.timesPerWeek = 0
            case .specificDays(let mask):
                goal.scheduleKindRaw = ScheduleKind.specificDays.rawValue
                goal.weekdayMask = mask; goal.timesPerWeek = 0
            case .timesPerWeek(let n):
                goal.scheduleKindRaw = ScheduleKind.timesPerWeek.rawValue
                goal.weekdayMask = 0; goal.timesPerWeek = n
            }
        } else {
            let newGoal = SelfCareGoal(title: trimmedTitle, category: category, schedule: schedule,
                                       pebbleReward: pebbleReward, energyReward: energyReward)
            modelContext.insert(newGoal)
        }
        do {
            try modelContext.save()
            settings.haptic(.success)
            dismiss()
        } catch {
            errorMessage = "Couldn't save your goal. Please try again."
        }
    }
}
