import SwiftUI
import SwiftData

// MARK: - Feed editor

/// Add or edit a feed. Handles both breast (kind + minutes) and bottle (volume).
struct FeedEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.volumeUnit) private var volumeUnitRaw = VolumeUnit.oz.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true

    let baby: Baby
    let existing: FeedLog?
    /// Optional preset (e.g. when tapping "Left" on Today).
    var presetKind: FeedKind? = nil
    /// Optional preset duration in seconds (from a finished timer).
    var presetSeconds: Int? = nil

    @State private var kind: FeedKind = .breastBoth
    @State private var date = Date()
    @State private var minutes: Double = 12
    @State private var displayVolume: Double = 4
    @State private var note = ""

    private var unit: VolumeUnit { VolumeUnit(rawValue: volumeUnitRaw) ?? .oz }
    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Feed type", selection: $kind) {
                        ForEach(FeedKind.allCases) { k in
                            Text(k.label).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if kind.isBreast {
                    Section("Duration") {
                        HStack {
                            Text("\(Int(minutes)) min")
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                            Spacer()
                        }
                        Slider(value: $minutes, in: 1...60, step: 1)
                            .accessibilityValue("\(Int(minutes)) minutes")
                    }
                } else {
                    Section("Volume") {
                        Stepper(value: $displayVolume, in: 0...unit.maxValue, step: unit.step) {
                            Text("\(Fmt.num(displayVolume)) \(unit.label)")
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                        }
                    }
                }

                Section("When") {
                    DatePicker("Time", selection: $date, in: ...Date())
                }

                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle(isEditing ? "Edit Feed" : "Add Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let existing {
            kind = existing.kind
            date = existing.date
            if existing.kind.isBreast {
                minutes = max(1, Double(existing.durationSeconds) / 60)
            } else {
                displayVolume = unit.display(fromML: existing.volumeML)
            }
            note = existing.note
        } else {
            if let presetKind { kind = presetKind }
            if let presetSeconds { minutes = max(1, Double(presetSeconds) / 60) }
        }
    }

    private func save() {
        let seconds = kind.isBreast ? Int(minutes * 60) : 0
        let ml = kind.isBreast ? 0 : unit.toML(displayVolume)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.kind = kind
            existing.date = date
            existing.durationSeconds = seconds
            existing.volumeML = ml
            existing.note = trimmedNote
        } else {
            let feed = FeedLog(date: date, kind: kind, durationSeconds: seconds, volumeML: ml, note: trimmedNote)
            baby.feeds.append(feed)
            context.insert(feed)
        }
        try? context.save()
        Haptics.success(haptics)
        dismiss()
    }
}

// MARK: - Diaper editor

struct DiaperEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true

    let baby: Baby
    let existing: DiaperLog?
    var presetKind: DiaperKind? = nil

    @State private var kind: DiaperKind = .wet
    @State private var date = Date()
    @State private var note = ""

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Diaper type", selection: $kind) {
                        ForEach(DiaperKind.allCases) { k in
                            Label(k.label, systemImage: k.systemImage).tag(k)
                        }
                    }
                    .pickerStyle(.inline)
                }
                Section("When") {
                    DatePicker("Time", selection: $date, in: ...Date())
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle(isEditing ? "Edit Diaper" : "Add Diaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let existing { kind = existing.kind; date = existing.date; note = existing.note }
                else if let presetKind { kind = presetKind }
            }
        }
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.kind = kind
            existing.date = date
            existing.note = trimmedNote
        } else {
            let log = DiaperLog(date: date, kind: kind, note: trimmedNote)
            baby.diapers.append(log)
            context.insert(log)
        }
        try? context.save()
        Haptics.success(haptics)
        dismiss()
    }
}

// MARK: - Sleep editor (manual start/end)

struct SleepEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true

    let baby: Baby
    let existing: SleepLog?

    @State private var start = Date().addingTimeInterval(-3600)
    @State private var end = Date()
    @State private var note = ""

    private var isEditing: Bool { existing != nil }
    private var valid: Bool { end >= start }

    var body: some View {
        NavigationStack {
            Form {
                Section("Asleep") {
                    DatePicker("Start", selection: $start, in: ...Date())
                    DatePicker("End", selection: $end, in: start...Date())
                }
                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(Fmt.duration(max(0, end.timeIntervalSince(start))))
                            .foregroundStyle(Theme.accentDeep)
                            .monospacedDigit()
                    }
                }
                if !valid {
                    Section {
                        Label("End must be after start.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(Theme.clay)
                            .font(.subheadline)
                    }
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle(isEditing ? "Edit Sleep" : "Add Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!valid)
                }
            }
            .onAppear {
                if let existing {
                    start = existing.start
                    end = existing.end ?? Date()
                    note = existing.note
                }
            }
        }
    }

    private func save() {
        guard valid else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.start = start
            existing.end = end
            existing.note = trimmedNote
        } else {
            let log = SleepLog(start: start, end: end, note: trimmedNote)
            baby.sleeps.append(log)
            context.insert(log)
        }
        try? context.save()
        Haptics.success(haptics)
        dismiss()
    }
}

// MARK: - Growth editor

struct GrowthEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.weightUnit) private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage(PrefKey.lengthUnit) private var lengthUnitRaw = LengthUnit.cm.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true

    let baby: Baby
    let existing: GrowthEntry?

    @State private var date = Date()
    @State private var recordWeight = true
    @State private var recordLength = true
    @State private var weight: Double = 4
    @State private var length: Double = 55
    @State private var note = ""

    private var wUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
    private var lUnit: LengthUnit { LengthUnit(rawValue: lengthUnitRaw) ?? .cm }
    private var isEditing: Bool { existing != nil }
    private var valid: Bool { recordWeight || recordLength }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section("Weight") {
                    Toggle("Record weight", isOn: $recordWeight)
                    if recordWeight {
                        Stepper(value: $weight, in: 0.5...20, step: wUnit == .kg ? 0.05 : 0.1) {
                            Text("\(Fmt.num(weight, decimals: 2)) \(wUnit.label)")
                                .monospacedDigit()
                        }
                    }
                }
                Section("Length") {
                    Toggle("Record length", isOn: $recordLength)
                    if recordLength {
                        Stepper(value: $length, in: 30...110, step: lUnit == .cm ? 0.5 : 0.25) {
                            Text("\(Fmt.num(length)) \(lUnit.label)")
                                .monospacedDigit()
                        }
                    }
                }
                if !valid {
                    Section {
                        Label("Record at least one measurement.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(Theme.clay)
                            .font(.subheadline)
                    }
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle(isEditing ? "Edit Measurement" : "Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!valid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let existing {
            date = existing.date
            recordWeight = existing.hasWeight
            recordLength = existing.hasLength
            if existing.hasWeight { weight = wUnit.display(fromGrams: existing.weightGrams) }
            if existing.hasLength { length = lUnit.display(fromCM: existing.lengthCM) }
            note = existing.note
        }
    }

    private func save() {
        guard valid else { return }
        let grams = recordWeight ? wUnit.toGrams(weight) : 0
        let cm = recordLength ? lUnit.toCM(length) : 0
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.date = date
            existing.weightGrams = grams
            existing.lengthCM = cm
            existing.note = trimmedNote
        } else {
            let entry = GrowthEntry(date: date, weightGrams: grams, lengthCM: cm, note: trimmedNote)
            baby.growth.append(entry)
            context.insert(entry)
        }
        try? context.save()
        Haptics.success(haptics)
        dismiss()
    }
}
