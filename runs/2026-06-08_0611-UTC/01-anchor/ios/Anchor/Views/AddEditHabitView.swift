import SwiftUI
import SwiftData

struct AddEditHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.order) private var habits: [Habit]

    let editingHabit: Habit?

    // MARK: - Form state
    @State private var name = ""
    @State private var symbol = "star.fill"
    @State private var colorHex: UInt32 = 0x4FB98C
    @State private var scheduleType: ScheduleType = .everyDay
    @State private var weekdayMask: Int = 0b1111111
    @State private var timesPerWeekTarget = 3
    @State private var dailyTarget = 1
    @State private var unit = ""
    @State private var polarity: Polarity = .build

    @State private var showSymbolPicker = false
    @State private var nameError: String?
    @State private var maskError: String?

    private var isEditing: Bool { editingHabit != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                Form {
                    // Name & icon
                    Section {
                        habitPreviewRow

                        TextField("Habit name", text: $name)
                            .foregroundStyle(Brand.text)
                            .onChange(of: name) { _, _ in nameError = nil }
                            .accessibilityLabel("Habit name")

                        if let err = nameError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(Brand.danger)
                        }

                        Button {
                            showSymbolPicker = true
                            Haptics.tap()
                        } label: {
                            HStack {
                                Text("Icon")
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Image(systemName: symbol)
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                        .accessibilityLabel("Choose icon, currently \(symbol)")
                    } header: {
                        Eyebrow(text: "Name & Appearance")
                    }

                    // Color
                    Section {
                        ColorSwatchPicker(selectedHex: $colorHex)
                            .padding(.vertical, 4)
                    } header: {
                        Eyebrow(text: "Color")
                    }

                    // Schedule
                    Section {
                        Picker("Schedule", selection: $scheduleType) {
                            ForEach(ScheduleType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Schedule type")

                        if scheduleType == .specificDays {
                            VStack(alignment: .leading, spacing: 8) {
                                WeekdayPicker(mask: $weekdayMask)
                                    .onChange(of: weekdayMask) { _, _ in maskError = nil }
                                if let err = maskError {
                                    Text(err)
                                        .font(.caption)
                                        .foregroundStyle(Brand.danger)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        if scheduleType == .timesPerWeek {
                            Stepper(
                                "\(timesPerWeekTarget) times per week",
                                value: $timesPerWeekTarget,
                                in: 1...7
                            )
                            .foregroundStyle(Brand.text)
                        }
                    } header: {
                        Eyebrow(text: "Schedule")
                    }

                    // Target
                    Section {
                        Stepper(
                            dailyTarget == 1
                                ? "Complete once per day"
                                : "\(dailyTarget)\(unit.isEmpty ? "" : " \(unit)") per day",
                            value: $dailyTarget,
                            in: 1...100
                        )
                        .foregroundStyle(Brand.text)
                        .accessibilityLabel("Daily target: \(dailyTarget)")

                        if dailyTarget > 1 {
                            TextField("Unit (e.g. glasses, pages)", text: $unit)
                                .foregroundStyle(Brand.text)
                                .accessibilityLabel("Unit label")
                        }
                    } header: {
                        Eyebrow(text: "Daily Target")
                    }

                    // Polarity
                    Section {
                        Picker("Type", selection: $polarity) {
                            ForEach(Polarity.allCases, id: \.self) { p in
                                Label(p.displayName, systemImage: p == .build ? "plus.circle" : "minus.circle")
                                    .tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Habit type")
                    } header: {
                        Eyebrow(text: "Type")
                    } footer: {
                        Text(polarity == .build
                             ? "Track progress toward a positive behavior."
                             : "Track abstaining from something you want to quit.")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Brand.text)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if validate() {
                            save()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Brand.live)
                }
            }
            .sheet(isPresented: $showSymbolPicker) {
                SymbolPicker(selected: $symbol)
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - Preview row

    private var habitPreviewRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex).opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: colorHex))
                    .accessibilityHidden(true)
            }
            Text(name.isEmpty ? "Habit Name" : name)
                .foregroundStyle(name.isEmpty ? Brand.text3 : Brand.text)
                .font(.body.weight(.medium))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Validation

    private func validate() -> Bool {
        var ok = true
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Name cannot be empty."
            ok = false
        }
        if scheduleType == .specificDays && weekdayMask == 0 {
            maskError = "Select at least one day."
            ok = false
        }
        if !ok { Haptics.warning() }
        return ok
    }

    // MARK: - Persistence

    private func loadExisting() {
        guard let h = editingHabit else { return }
        name = h.name
        symbol = h.symbol
        colorHex = h.colorHex
        scheduleType = h.scheduleType
        weekdayMask = h.weekdayMask
        timesPerWeekTarget = h.timesPerWeekTarget
        dailyTarget = h.dailyTarget
        unit = h.unit
        polarity = h.polarity
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let h = editingHabit {
            h.name = trimmed
            h.symbol = symbol
            h.colorHex = colorHex
            h.scheduleType = scheduleType
            h.weekdayMask = scheduleType == .specificDays ? weekdayMask : 0b1111111
            h.timesPerWeekTarget = timesPerWeekTarget
            h.dailyTarget = max(1, dailyTarget)
            h.unit = dailyTarget > 1 ? unit : ""
            h.polarity = polarity
        } else {
            let newOrder = habits.map(\.order).max().map { $0 + 1 } ?? 0
            let habit = Habit(
                name: trimmed,
                symbol: symbol,
                colorHex: colorHex,
                scheduleType: scheduleType,
                weekdayMask: scheduleType == .specificDays ? weekdayMask : 0b1111111,
                timesPerWeekTarget: timesPerWeekTarget,
                dailyTarget: max(1, dailyTarget),
                unit: dailyTarget > 1 ? unit : "",
                polarity: polarity,
                order: newOrder
            )
            context.insert(habit)
        }
        Haptics.success()
        dismiss()
    }
}
