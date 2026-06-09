import SwiftUI
import SwiftData

struct RoutineBuilderView: View {
    /// nil → create a new routine; non-nil → edit it.
    let routine: Routine?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Stretch.name) private var library: [Stretch]

    @State private var name = ""
    @State private var summary = ""
    @State private var drafts: [Draft] = []
    @State private var picking = false

    struct Draft: Identifiable {
        let id = UUID()
        let stretch: Stretch
        var seconds: Int
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !drafts.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Routine name", text: $name)
                    TextField("Short description (optional)", text: $summary, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section {
                    if drafts.isEmpty {
                        Text("Add stretches to build your sequence.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    } else {
                        ForEach($drafts) { $draft in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: draft.stretch.area.icon)
                                        .foregroundStyle(draft.stretch.area.tint)
                                        .accessibilityHidden(true)
                                    Text(draft.stretch.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    if draft.stretch.bothSides {
                                        Text("per side").font(.caption2).foregroundStyle(Brand.text3)
                                    }
                                }
                                Stepper(value: $draft.seconds, in: 5...300, step: 5) {
                                    Text("\(draft.seconds) seconds")
                                        .font(Brand.mono(14))
                                        .foregroundStyle(Brand.text2)
                                }
                            }
                        }
                        .onDelete { drafts.remove(atOffsets: $0) }
                        .onMove { drafts.move(fromOffsets: $0, toOffset: $1) }
                    }

                    Button {
                        Haptics.tap()
                        picking = true
                    } label: {
                        Label("Add stretch", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Sequence")
                        Spacer()
                        if !drafts.isEmpty {
                            Text(MobilityEngine.secondsString(totalSeconds))
                                .font(Brand.mono(12))
                                .textCase(nil)
                        }
                    }
                }
            }
            .navigationTitle(routine == nil ? "New routine" : "Edit routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(!canSave)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !drafts.isEmpty { EditButton() }
                }
            }
            .sheet(isPresented: $picking) {
                StretchPickerView(library: library) { stretch in
                    drafts.append(Draft(stretch: stretch, seconds: stretch.defaultSeconds))
                }
            }
            .onAppear(perform: load)
        }
    }

    private var totalSeconds: Int {
        drafts.reduce(0) { $0 + ($1.stretch.bothSides ? $1.seconds * 2 : $1.seconds) }
    }

    private func load() {
        guard let routine, drafts.isEmpty, name.isEmpty else { return }
        name = routine.name
        summary = routine.summary
        drafts = routine.orderedSteps.compactMap { step in
            step.stretch.map { Draft(stretch: $0, seconds: step.seconds) }
        }
    }

    private func save() {
        let target: Routine
        if let routine {
            target = routine
            target.name = name.trimmingCharacters(in: .whitespaces)
            target.summary = summary.trimmingCharacters(in: .whitespaces)
            for old in target.steps { context.delete(old) }
            target.steps = []
        } else {
            target = Routine(name: name.trimmingCharacters(in: .whitespaces),
                             summary: summary.trimmingCharacters(in: .whitespaces))
            context.insert(target)
        }
        for (i, draft) in drafts.enumerated() {
            let step = RoutineStep(order: i, seconds: draft.seconds, stretch: draft.stretch)
            step.routine = target
            context.insert(step)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

/// Pick a stretch from the library, grouped by body area.
struct StretchPickerView: View {
    let library: [Stretch]
    let onPick: (Stretch) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var grouped: [(BodyArea, [Stretch])] {
        let filtered = query.isEmpty ? library :
            library.filter { $0.name.localizedCaseInsensitiveContains(query) }
        return BodyArea.allCases.compactMap { area in
            let items = filtered.filter { $0.area == area }.sorted { $0.name < $1.name }
            return items.isEmpty ? nil : (area, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if grouped.isEmpty {
                    Text("No stretches match “\(query)”.")
                        .foregroundStyle(Brand.text3)
                }
                ForEach(grouped, id: \.0) { area, items in
                    Section(area.title) {
                        ForEach(items) { stretch in
                            Button {
                                Haptics.selection()
                                onPick(stretch)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: stretch.area.icon)
                                        .foregroundStyle(stretch.area.tint)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(stretch.name).foregroundStyle(Brand.text)
                                        Text(stretch.difficultyLabel)
                                            .font(.caption).foregroundStyle(Brand.text3)
                                    }
                                    Spacer()
                                    Text("\(stretch.defaultSeconds)s")
                                        .font(Brand.mono(13)).foregroundStyle(Brand.text3)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search stretches")
            .navigationTitle("Add stretch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
