import SwiftUI
import SwiftData

/// Configure a drill: name, type, which items are enabled, direction, root mode.
/// Validates that at least one item is enabled before allowing save.
struct DrillEditorView: View {
    @Bindable var drill: Drill
    var isNew: Bool = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showValidation = false

    private var enabledSet: Set<String> { Set(drill.enabledKeys) }
    private var isValid: Bool { !drill.enabledKeys.isEmpty }

    /// Harmonic direction only makes sense for intervals/chords.
    private var availableDirections: [PlayDirection] {
        drill.type == .scale ? [.ascending, .descending] : PlayDirection.allCases
    }

    var body: some View {
        Form {
            Section("Drill") {
                TextField("Name", text: $drill.name)
                    .disabled(drill.isBuiltIn)
                Picker("Type", selection: typeBinding) {
                    ForEach(DrillType.allCases) { Text($0.label).tag($0) }
                }
                .disabled(drill.isBuiltIn)
            }

            Section {
                ForEach(itemOptions, id: \.raw) { option in
                    Toggle(option.label, isOn: itemBinding(option.raw))
                        .disabled(drill.isBuiltIn)
                }
            } header: {
                Text("Items in play")
            } footer: {
                if !isValid {
                    Text("Enable at least one item.")
                        .foregroundStyle(Brand.danger)
                }
            }

            Section("Playback") {
                Picker("Direction", selection: directionBinding) {
                    ForEach(availableDirections) { Text($0.label).tag($0) }
                }
                .disabled(drill.isBuiltIn)
                Picker("Root", selection: $drill.rootModeRaw) {
                    ForEach(RootMode.allCases) { Text($0.label).tag($0.rawValue) }
                }
                .disabled(drill.isBuiltIn)
            }

            if drill.isBuiltIn {
                Section {
                    Text("Built-in drills can't be edited. Create a custom drill to choose your own items.")
                        .font(.footnote)
                        .foregroundStyle(Brand.text2)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(isNew ? "New Drill" : drill.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
        .onDisappear {
            // Persist edits if still valid; otherwise restore a default set.
            if !isValid { drill.enabledKeys = Drill.defaultKeys(for: drill.type) }
            try? context.save()
        }
    }

    // MARK: - Item options for the current type

    private var itemOptions: [(raw: String, label: String)] {
        switch drill.type {
        case .interval:
            return Interval.allCases.filter { $0 != .unison }.map { ($0.rawValue, $0.label) }
        case .chord:
            return ChordType.allCases.map { ($0.rawValue, $0.label) }
        case .scale:
            return ScaleType.allCases.map { ($0.rawValue, $0.label) }
        }
    }

    // MARK: - Bindings

    private var typeBinding: Binding<DrillType> {
        Binding(
            get: { drill.type },
            set: { newType in
                drill.type = newType
                // Reset items and direction to valid defaults for the new type.
                drill.enabledKeys = Drill.defaultKeys(for: newType)
                if newType == .scale, drill.direction == .harmonic {
                    drill.direction = .ascending
                }
            }
        )
    }

    private var directionBinding: Binding<PlayDirection> {
        Binding(
            get: {
                let d = drill.direction
                return (drill.type == .scale && d == .harmonic) ? .ascending : d
            },
            set: { drill.direction = $0 }
        )
    }

    private func itemBinding(_ raw: String) -> Binding<Bool> {
        Binding(
            get: { enabledSet.contains(raw) },
            set: { on in
                var set = enabledSet
                if on { set.insert(raw) } else { set.remove(raw) }
                // Keep canonical order so the list and grids stay stable.
                drill.enabledKeys = itemOptions.map(\.raw).filter { set.contains($0) }
                Haptics.selection()
            }
        )
    }

    private func save() {
        guard isValid else { showValidation = true; return }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
