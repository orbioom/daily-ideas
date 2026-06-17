import SwiftUI
import SwiftData

/// Draft of a single set while building (value type, not yet persisted).
struct DraftSet: Identifiable {
    let id = UUID()
    var repeats: Int
    var distance: Double      // meters
    var stroke: Stroke
    var sendOff: Int
    var rest: Int
    var effort: Effort
    var note: String

    var totalMeters: Double { Double(max(1, repeats)) * max(0, distance) }
}

/// Build a new workout or edit an existing custom one.
struct WorkoutBuilderView: View {
    var existing: SwimWorkout?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue
    @AppStorage(PrefKey.poolLengthRaw) private var poolLengthRaw = PoolLength.scm25.rawValue
    @AppStorage(PrefKey.defaultRestSeconds) private var defaultRestSeconds = 20
    @AppStorage(PrefKey.defaultStrokeRaw) private var defaultStrokeRaw = Stroke.freestyle.rawValue

    @State private var name: String = ""
    @State private var type: WorkoutType = .custom
    @State private var notes: String = ""
    @State private var drafts: [DraftSet] = []
    @State private var editingSet: DraftSet?
    @State private var showingNewSet = false

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }
    private var poolLength: PoolLength { PoolLength(rawValue: poolLengthRaw) ?? .scm25 }

    private var totalMeters: Double { drafts.reduce(0) { $0 + $1.totalMeters } }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !drafts.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(WorkoutType.allCases) { t in
                            Text(t.label).tag(t)
                        }
                    }
                }

                Section {
                    if drafts.isEmpty {
                        Text("Add at least one set to build your workout.")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        ForEach(drafts) { draft in
                            Button {
                                editingSet = draft
                            } label: {
                                draftRow(draft)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            drafts.remove(atOffsets: offsets)
                        }
                        .onMove { from, to in
                            drafts.move(fromOffsets: from, toOffset: to)
                        }
                    }
                    Button {
                        showingNewSet = true
                    } label: {
                        Label("Add set", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.accent)
                    }
                } header: {
                    HStack {
                        Text("Sets")
                        Spacer()
                        if totalMeters > 0 {
                            Text("\(Int(totalMeters)) m total")
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional coaching notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle(existing == nil ? "New Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !drafts.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingNewSet) {
                SetEditorView(draft: newDraft(), unit: unit) { result in
                    drafts.append(result)
                }
            }
            .sheet(item: $editingSet) { draft in
                SetEditorView(draft: draft, unit: unit) { result in
                    if let idx = drafts.firstIndex(where: { $0.id == result.id }) {
                        drafts[idx] = result
                    }
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func draftRow(_ draft: DraftSet) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(draft.repeats) × \(Int(unit.value(fromMeters: draft.distance))) \(unit.shortUnit) \(draft.stroke.label)")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 6) {
                Pill(text: draft.effort.label, color: draft.effort.hue)
                if draft.sendOff > 0 {
                    Pill(text: "@ \(UnitFormatter.clock(Double(draft.sendOff)))", color: Theme.accentDeep)
                } else if draft.rest > 0 {
                    Pill(text: "rest \(draft.rest)s", color: Theme.good)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func newDraft() -> DraftSet {
        DraftSet(repeats: 4,
                 distance: 100,
                 stroke: Stroke.from(defaultStrokeRaw),
                 sendOff: 0,
                 rest: max(0, defaultRestSeconds),
                 effort: .moderate,
                 note: "")
    }

    private func loadExisting() {
        guard let existing, drafts.isEmpty, name.isEmpty else { return }
        name = existing.name
        type = existing.type
        notes = existing.notes
        drafts = existing.orderedSets.map { set in
            DraftSet(repeats: set.repeats,
                     distance: set.distancePerRepMeters,
                     stroke: set.stroke,
                     sendOff: set.sendOffSeconds,
                     rest: set.restSeconds,
                     effort: set.effort,
                     note: set.note)
        }
    }

    private func save() {
        guard canSave else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let target: SwimWorkout
        if let existing {
            target = existing
            // Replace sets wholesale for simplicity and correctness.
            for old in existing.sets { context.delete(old) }
            existing.sets.removeAll()
            target.name = trimmed
            target.type = type
            target.notes = notes
            target.poolLengthMeters = existing.poolLengthMeters
        } else {
            target = SwimWorkout(name: trimmed,
                                 poolLengthMeters: poolLength.meters,
                                 type: type,
                                 notes: notes,
                                 isBuiltIn: false)
            context.insert(target)
        }
        for (index, draft) in drafts.enumerated() {
            let set = SwimSet(order: index,
                              repeats: draft.repeats,
                              distancePerRepMeters: draft.distance,
                              stroke: draft.stroke,
                              sendOffSeconds: draft.sendOff,
                              restSeconds: draft.rest,
                              effort: draft.effort,
                              note: draft.note)
            set.workout = target
            target.sets.append(set)
        }
        try? context.save()
        Haptics.success(hapticsEnabled)
        dismiss()
    }
}
