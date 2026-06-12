import SwiftUI
import SwiftData

struct PatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShiftType.createdAt) private var shiftTypes: [ShiftType]
    @Query(sort: \RotationPattern.createdAt) private var patterns: [RotationPattern]
    @AppStorage("use24Hour") private var use24Hour = true

    var body: some View {
        NavigationStack {
            List {
                shiftTypesSection
                patternsSection
                if shiftTypes.isEmpty && patterns.isEmpty {
                    presetsSection
                }
            }
            .navigationTitle("Rotation")
        }
    }

    // MARK: - Shift types

    private var shiftTypesSection: some View {
        Section {
            if shiftTypes.isEmpty {
                Text("No shift types yet. A shift type is a kind of day — Day, Night, Off — with its hours and pay rate.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(shiftTypes) { type in
                NavigationLink {
                    ShiftTypeEditor(type: type)
                } label: {
                    HStack(spacing: 10) {
                        ShiftBadge(symbol: type.symbol, colorHex: type.colorHex, small: true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(type.name).font(.body.weight(.medium))
                            Text(type.isRest
                                 ? "Rest day"
                                 : "\(type.timeRangeString(use24Hour: use24Hour)) · \(type.paidHours.formatted(.number.precision(.fractionLength(0...1)))) h paid")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets where index < shiftTypes.count {
                    modelContext.delete(shiftTypes[index])
                }
            }
            Button {
                Haptics.tap()
                let palette = RotaTheme.shiftPalette
                let used = Set(shiftTypes.map(\.colorHex))
                let color = palette.first { !used.contains($0) } ?? palette[shiftTypes.count % palette.count]
                let type = ShiftType(name: "New Shift", symbol: "S", colorHex: color)
                modelContext.insert(type)
            } label: {
                Label("Add Shift Type", systemImage: "plus")
            }
        } header: {
            Text("Shift Types")
        } footer: {
            shiftTypes.isEmpty ? nil : Text("Deleting a shift type clears it from any pattern slots and overrides that used it.")
        }
    }

    // MARK: - Patterns

    private var patternsSection: some View {
        Section {
            ForEach(patterns) { pattern in
                NavigationLink {
                    PatternEditor(pattern: pattern)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pattern.name).font(.body.weight(.medium))
                            Text("\(pattern.sortedSlots.count)-day cycle from \(pattern.anchorDay.formatted(.dateTime.day().month()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if pattern.isActive {
                            Text("Active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RotaTheme.amber)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(pattern)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    if !pattern.isActive {
                        Button {
                            activate(pattern)
                        } label: {
                            Label("Activate", systemImage: "checkmark.circle")
                        }
                        .tint(RotaTheme.amber)
                    }
                }
            }
            Button {
                Haptics.tap()
                let pattern = RotationPattern(
                    name: "My Rotation",
                    anchorDay: Calendar.current.startOfDay(for: .now),
                    isActive: patterns.isEmpty
                )
                modelContext.insert(pattern)
            } label: {
                Label("Add Rotation", systemImage: "plus")
            }
        } header: {
            Text("Rotations")
        } footer: {
            Text("The active rotation fills the calendar. Swipe a rotation to activate it — handy when your roster changes.")
        }
    }

    private func activate(_ pattern: RotationPattern) {
        Haptics.tap()
        for p in patterns {
            p.isActive = (p.persistentModelID == pattern.persistentModelID)
        }
    }

    // MARK: - Presets

    private var presetsSection: some View {
        Section {
            Button { makeFourOnFourOff() } label: {
                presetRow("4 on, 4 off", detail: "Four 12-hour days, four off — common in healthcare, plants, and emergency services.")
            }
            Button { makeDayNightRotation() } label: {
                presetRow("2 days, 2 nights, 4 off", detail: "The classic continental-style day/night rotation.")
            }
            Button { makeFiveTwo() } label: {
                presetRow("5 on, 2 off", detail: "A standard working week, useful as a starting point.")
            }
        } header: {
            Text("Quick Start")
        } footer: {
            Text("One tap creates the shift types and rotation, anchored to today. Adjust hours and rates afterwards.")
        }
    }

    private func presetRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func makeFourOnFourOff() {
        Haptics.success()
        let day = ShiftType(name: "Day", symbol: "D", colorHex: "E8A33D", startMinutes: 7 * 60, endMinutes: 19 * 60, unpaidBreakMinutes: 30)
        let off = ShiftType(name: "Off", symbol: "—", colorHex: "8A8F99", isRest: true)
        modelContext.insert(day)
        modelContext.insert(off)
        insertPattern(name: "4 on 4 off", types: [day, day, day, day, off, off, off, off])
    }

    private func makeDayNightRotation() {
        Haptics.success()
        let day = ShiftType(name: "Day", symbol: "D", colorHex: "E8A33D", startMinutes: 7 * 60, endMinutes: 19 * 60, unpaidBreakMinutes: 30)
        let night = ShiftType(name: "Night", symbol: "N", colorHex: "4D8DE8", startMinutes: 19 * 60, endMinutes: 7 * 60, unpaidBreakMinutes: 30)
        let off = ShiftType(name: "Off", symbol: "—", colorHex: "8A8F99", isRest: true)
        modelContext.insert(day)
        modelContext.insert(night)
        modelContext.insert(off)
        insertPattern(name: "2D 2N 4 off", types: [day, day, night, night, off, off, off, off])
    }

    private func makeFiveTwo() {
        Haptics.success()
        let day = ShiftType(name: "Day", symbol: "D", colorHex: "47A36B", startMinutes: 9 * 60, endMinutes: 17 * 60, unpaidBreakMinutes: 30)
        let off = ShiftType(name: "Off", symbol: "—", colorHex: "8A8F99", isRest: true)
        modelContext.insert(day)
        modelContext.insert(off)
        insertPattern(name: "5 on 2 off", types: [day, day, day, day, day, off, off])
    }

    private func insertPattern(name: String, types: [ShiftType]) {
        let pattern = RotationPattern(name: name, anchorDay: Calendar.current.startOfDay(for: .now), isActive: true)
        modelContext.insert(pattern)
        for (index, type) in types.enumerated() {
            let slot = PatternSlot(orderIndex: index, shiftType: type)
            slot.pattern = pattern
            modelContext.insert(slot)
        }
    }
}

// MARK: - Shift type editor

struct ShiftTypeEditor: View {
    @Bindable var type: ShiftType
    @AppStorage("currencySymbol") private var currencySymbol = "$"

    private func timeBinding(_ keyPath: ReferenceWritableKeyPath<ShiftType, Int>) -> Binding<Date> {
        Binding<Date>(
            get: {
                let start = Calendar.current.startOfDay(for: .now)
                return Calendar.current.date(byAdding: .minute, value: type[keyPath: keyPath], to: start) ?? start
            },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                type[keyPath: keyPath] = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        )
    }

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name (e.g. Day, Night, Late)", text: $type.name)
                TextField("Badge (1–3 letters)", text: Binding(
                    get: { type.symbol },
                    set: { type.symbol = String($0.prefix(3)).uppercased() }
                ))
                HStack(spacing: 10) {
                    Text("Color")
                    Spacer()
                    ForEach(RotaTheme.shiftPalette, id: \.self) { hex in
                        Button {
                            Haptics.tap()
                            type.colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 24, height: 24)
                                .overlay {
                                    if type.colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Color \(hex)\(type.colorHex == hex ? ", selected" : "")")
                    }
                }
            }

            Section {
                Toggle("Rest day (no hours, no pay)", isOn: $type.isRest)
            }

            if !type.isRest {
                Section {
                    DatePicker("Starts", selection: timeBinding(\.startMinutes), displayedComponents: .hourAndMinute)
                    DatePicker("Ends", selection: timeBinding(\.endMinutes), displayedComponents: .hourAndMinute)
                    Stepper(value: $type.unpaidBreakMinutes, in: 0...240, step: 15) {
                        LabeledContent("Unpaid break", value: "\(type.unpaidBreakMinutes) min")
                    }
                } header: {
                    Text("Hours")
                } footer: {
                    Text(type.endMinutes <= type.startMinutes
                         ? "This shift crosses midnight — it ends the next day. Paid: \(type.paidHours.formatted(.number.precision(.fractionLength(0...2)))) h."
                         : "Paid: \(type.paidHours.formatted(.number.precision(.fractionLength(0...2)))) h after the break.")
                }

                Section {
                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("Hourly rate", value: $type.hourlyRate, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Pay")
                } footer: {
                    Text(type.hourlyRate > 0
                         ? "≈ \(Money.format(type.earningsPerShift, symbol: currencySymbol)) per shift."
                         : "Leave at 0 to track hours without pay estimates.")
                }
            }
        }
        .navigationTitle(type.name.isEmpty ? "Shift Type" : type.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Pattern editor

struct PatternEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var pattern: RotationPattern
    @Query(sort: \ShiftType.createdAt) private var shiftTypes: [ShiftType]

    var body: some View {
        Form {
            Section("Rotation") {
                TextField("Name", text: $pattern.name)
                DatePicker(
                    "Cycle starts on",
                    selection: Binding(
                        get: { pattern.anchorDay },
                        set: { pattern.anchorDay = Calendar.current.startOfDay(for: $0) }
                    ),
                    displayedComponents: .date
                )
                Toggle("Active", isOn: Binding(
                    get: { pattern.isActive },
                    set: { pattern.isActive = $0; Haptics.tap() }
                ))
            }

            Section {
                if pattern.sortedSlots.isEmpty {
                    Text("Add days below — the cycle repeats forever from the start date. Day 1 of the cycle falls on the start date.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(pattern.sortedSlots) { slot in
                    HStack(spacing: 10) {
                        Text("Day \(slot.orderIndex + 1)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .leading)
                        if let type = slot.shiftType {
                            ShiftBadge(symbol: type.symbol, colorHex: type.colorHex, small: true)
                            Text(type.name)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.orange)
                            Text("Missing type")
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        Menu {
                            ForEach(shiftTypes) { type in
                                Button(type.name) {
                                    Haptics.tap()
                                    slot.shiftType = type
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.subheadline)
                        }
                        .accessibilityLabel("Change day \(slot.orderIndex + 1)")
                    }
                    .accessibilityElement(children: .combine)
                }
                .onDelete { offsets in
                    let sorted = pattern.sortedSlots
                    for index in offsets where index < sorted.count {
                        modelContext.delete(sorted[index])
                    }
                    reindex()
                }
                .onMove { source, destination in
                    var working = pattern.sortedSlots
                    working.move(fromOffsets: source, toOffset: destination)
                    for (index, slot) in working.enumerated() {
                        slot.orderIndex = index
                    }
                }

                if shiftTypes.isEmpty {
                    Text("Create a shift type first.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Menu {
                        ForEach(shiftTypes) { type in
                            Button(type.name) {
                                Haptics.tap()
                                let slot = PatternSlot(
                                    orderIndex: (pattern.slots.map(\.orderIndex).max() ?? -1) + 1,
                                    shiftType: type
                                )
                                slot.pattern = pattern
                                modelContext.insert(slot)
                            }
                        }
                    } label: {
                        Label("Add Day to Cycle", systemImage: "plus")
                    }
                }
            } header: {
                Text("Cycle — \(pattern.sortedSlots.count) day\(pattern.sortedSlots.count == 1 ? "" : "s")")
            } footer: {
                Text("Swipe to delete · drag in Edit mode to reorder.")
            }
        }
        .navigationTitle(pattern.name.isEmpty ? "Rotation" : pattern.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }

    private func reindex() {
        for (index, slot) in pattern.sortedSlots.enumerated() {
            slot.orderIndex = index
        }
    }
}
