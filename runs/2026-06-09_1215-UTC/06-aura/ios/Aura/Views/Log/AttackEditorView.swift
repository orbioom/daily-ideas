import SwiftUI
import SwiftData

/// Create or edit an attack. Drives all the relationship editing (triggers,
/// symptoms, meds) plus validation (end ≥ start, intensity 1–10, dose ≥ 0).
struct AttackEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Trigger.name) private var allTriggers: [Trigger]
    @Query(sort: \Symptom.name) private var allSymptoms: [Symptom]
    @Query(sort: \Medication.name) private var catalog: [Medication]

    /// nil = creating a new attack.
    let existing: Attack?

    @AppStorage("aura.defaultType") private var defaultTypeRaw = HeadacheType.migraine.rawValue

    // Draft state
    @State private var start = Date()
    @State private var hasEnded = true
    @State private var end = Date()
    @State private var intensity = 5
    @State private var type: HeadacheType = .migraine
    @State private var location: HeadLocation = .unspecified
    @State private var auraPresent = false
    @State private var note = ""
    @State private var selectedTriggers: Set<PersistentIdentifier> = []
    @State private var selectedSymptoms: Set<PersistentIdentifier> = []
    @State private var draftMeds: [DraftMed] = []

    @State private var showAddTrigger = false
    @State private var showAddSymptom = false
    @State private var newTriggerName = ""
    @State private var newSymptomName = ""
    @State private var showMedSheet = false

    private var isValid: Bool {
        (!hasEnded || end >= start) && (1...10).contains(intensity)
    }

    var body: some View {
        NavigationStack {
            Form {
                timingSection
                intensitySection
                classificationSection
                triggersSection
                symptomsSection
                medsSection
                noteSection
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(existing == nil ? "Log Attack" : "Edit Attack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
            .sheet(isPresented: $showMedSheet) {
                MedEntryView(catalog: catalog) { draft in
                    draftMeds.append(draft)
                    Haptics.tap()
                }
            }
        }
    }

    // MARK: Sections

    private var timingSection: some View {
        Section("When") {
            DatePicker("Started", selection: $start)
            Toggle("Has ended", isOn: $hasEnded.animation(Brand.ease(0.2)))
            if hasEnded {
                DatePicker("Ended", selection: $end, in: start...)
                if end < start {
                    Label("End must be after the start.", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(Brand.danger)
                }
            } else {
                Label("This attack is still ongoing.", systemImage: "clock")
                    .font(.footnote)
                    .foregroundStyle(Brand.warn)
            }
        }
    }

    private var intensitySection: some View {
        Section("Intensity") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    IntensityDot(intensity: intensity)
                    Spacer()
                    Text(IntensityScale.label(intensity))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(IntensityScale.color(intensity))
                }
                Slider(value: Binding(
                    get: { Double(intensity) },
                    set: { intensity = Int($0.rounded()) }
                ), in: 1...10, step: 1)
                .tint(IntensityScale.color(intensity))
                .accessibilityLabel("Pain intensity")
                .accessibilityValue("\(intensity) of 10, \(IntensityScale.label(intensity))")
            }
        }
    }

    private var classificationSection: some View {
        Section("Type & location") {
            Picker("Type", selection: $type) {
                ForEach(HeadacheType.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
            }
            Picker("Location", selection: $location) {
                ForEach(HeadLocation.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Visual aura present", isOn: $auraPresent)
        }
    }

    private var triggersSection: some View {
        Section("Triggers") {
            chipFlow(items: allTriggers.map { ChipItem(id: $0.persistentModelID, name: $0.name, symbol: $0.category.symbol) },
                     selection: selectedTriggers) { id in
                toggle(&selectedTriggers, id)
            }
            Button {
                showAddTrigger = true
            } label: {
                Label("Add custom trigger", systemImage: "plus.circle")
            }
            .alert("New trigger", isPresented: $showAddTrigger) {
                TextField("Name", text: $newTriggerName)
                Button("Add") { addTrigger() }
                Button("Cancel", role: .cancel) { newTriggerName = "" }
            }
        }
    }

    private var symptomsSection: some View {
        Section("Symptoms") {
            chipFlow(items: allSymptoms.map { ChipItem(id: $0.persistentModelID, name: $0.name, symbol: nil) },
                     selection: selectedSymptoms) { id in
                toggle(&selectedSymptoms, id)
            }
            Button {
                showAddSymptom = true
            } label: {
                Label("Add custom symptom", systemImage: "plus.circle")
            }
            .alert("New symptom", isPresented: $showAddSymptom) {
                TextField("Name", text: $newSymptomName)
                Button("Add") { addSymptom() }
                Button("Cancel", role: .cancel) { newSymptomName = "" }
            }
        }
    }

    private var medsSection: some View {
        Section("Medications taken") {
            if draftMeds.isEmpty {
                Text("None recorded.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                ForEach(draftMeds) { med in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(med.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Spacer()
                            Text(Format.dose(med.doseMg)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                        }
                        Text("\(med.minutesAfterOnset) min after onset · \(med.relief.label)")
                            .font(.caption)
                            .foregroundStyle(med.relief.tint)
                    }
                    .accessibilityElement(children: .combine)
                }
                .onDelete { draftMeds.remove(atOffsets: $0) }
            }
            Button {
                showMedSheet = true
            } label: {
                Label("Add medication", systemImage: "pills")
            }
        }
    }

    private var noteSection: some View {
        Section("Note") {
            TextField("Anything else worth remembering…", text: $note, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    // MARK: Chip flow

    @ViewBuilder
    private func chipFlow(items: [ChipItem],
                          selection: Set<PersistentIdentifier>,
                          toggle: @escaping (PersistentIdentifier) -> Void) -> some View {
        if items.isEmpty {
            Text("Add some in Manage first.")
                .font(.subheadline)
                .foregroundStyle(Brand.text3)
        } else {
            FlowLayout(spacing: 8) {
                ForEach(items) { item in
                    SelectChip(text: item.name,
                               isSelected: selection.contains(item.id),
                               systemImage: item.symbol) {
                        Haptics.selection()
                        toggle(item.id)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: Actions

    private func toggle(_ set: inout Set<PersistentIdentifier>, _ id: PersistentIdentifier) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
    }

    private func addTrigger() {
        let name = newTriggerName.trimmingCharacters(in: .whitespacesAndNewlines)
        newTriggerName = ""
        guard !name.isEmpty else { return }
        let t = Trigger(name: name, category: .other, isBuiltIn: false)
        context.insert(t)
        try? context.save()
        selectedTriggers.insert(t.persistentModelID)
        Haptics.tap()
    }

    private func addSymptom() {
        let name = newSymptomName.trimmingCharacters(in: .whitespacesAndNewlines)
        newSymptomName = ""
        guard !name.isEmpty else { return }
        let s = Symptom(name: name, isBuiltIn: false)
        context.insert(s)
        try? context.save()
        selectedSymptoms.insert(s.persistentModelID)
        Haptics.tap()
    }

    private func load() {
        if let a = existing {
            start = a.start
            hasEnded = a.end != nil
            end = a.end ?? max(a.start, Date())
            intensity = a.intensity
            type = a.type
            location = a.location
            auraPresent = a.auraPresent
            note = a.note
            selectedTriggers = Set(a.triggers.map { $0.persistentModelID })
            selectedSymptoms = Set(a.symptoms.map { $0.persistentModelID })
            draftMeds = a.meds.map {
                DraftMed(name: $0.name, doseMg: $0.doseMg, minutesAfterOnset: $0.minutesAfterOnset,
                         relief: $0.relief, isAcute: $0.isAcute)
            }
        } else {
            type = HeadacheType(rawValue: defaultTypeRaw) ?? .migraine
        }
    }

    private func save() {
        guard isValid else { return }
        let triggers = allTriggers.filter { selectedTriggers.contains($0.persistentModelID) }
        let symptoms = allSymptoms.filter { selectedSymptoms.contains($0.persistentModelID) }

        let attack: Attack
        if let a = existing {
            attack = a
            // Replace cascade-owned meds.
            for old in a.meds { context.delete(old) }
            a.meds = []
        } else {
            attack = Attack()
            context.insert(attack)
        }

        attack.start = start
        attack.end = hasEnded ? end : nil
        attack.intensity = min(max(intensity, 1), 10)
        attack.type = type
        attack.location = location
        attack.auraPresent = auraPresent
        attack.note = note
        attack.triggers = triggers
        attack.symptoms = symptoms

        for d in draftMeds {
            let m = MedTaken(name: d.name, doseMg: d.doseMg, minutesAfterOnset: d.minutesAfterOnset,
                             relief: d.relief, isAcute: d.isAcute)
            m.attack = attack
            context.insert(m)
        }

        try? context.save()
        Haptics.success()
        dismiss()
    }
}

/// A lightweight item used to render selectable trigger / symptom chips.
struct ChipItem: Identifiable {
    let id: PersistentIdentifier
    let name: String
    let symbol: String?
}

/// A pending medication entry held in editor state before save.
struct DraftMed: Identifiable {
    let id = UUID()
    var name: String
    var doseMg: Double
    var minutesAfterOnset: Int
    var relief: Relief
    var isAcute: Bool
}
