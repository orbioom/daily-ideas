import SwiftUI
import SwiftData

/// Create or edit a preset. A nil `preset` means "new". Editing mutates the model
/// in place; creating inserts a fresh one with the next sort index.
struct PresetEditorView: View {
    let preset: MeditationPreset?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allPresets: [MeditationPreset]

    @State private var name = ""
    @State private var minutes = 10
    @State private var warmup = 10
    @State private var intervalMinutes = 0
    @State private var startBell: BellTone = .bowl
    @State private var intervalBell: BellTone = .chime
    @State private var endBell: BellTone = .bowl

    private var isNew: Bool { preset == nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && minutes >= 1 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Morning sit", text: $name)
                        .accessibilityLabel("Preset name")
                }

                Section("Timing") {
                    Stepper(value: $minutes, in: 1...240) {
                        labelValue("Length", "\(minutes) min")
                    }
                    Stepper(value: $warmup, in: 0...120, step: 5) {
                        labelValue("Warm-up", warmup == 0 ? "None" : "\(warmup)s")
                    }
                    Stepper(value: $intervalMinutes, in: 0...60) {
                        labelValue("Interval bell",
                                   intervalMinutes == 0 ? "Off" : "Every \(intervalMinutes) min")
                    }
                }

                Section("Bells") {
                    bellPicker("Start", selection: $startBell)
                    if intervalMinutes > 0 {
                        bellPicker("Interval", selection: $intervalBell)
                    }
                    bellPicker("End", selection: $endBell)
                }

                if !isNew, let preset, !preset.isBuiltIn {
                    Section {
                        Button(role: .destructive) {
                            context.delete(preset)
                            try? context.save()
                            Haptics.warning()
                            dismiss()
                        } label: {
                            Label("Delete preset", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isNew ? "New preset" : "Edit preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func labelValue(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(Brand.text2).font(Brand.mono(15))
        }
    }

    private func bellPicker(_ title: String, selection: Binding<BellTone>) -> some View {
        Picker(title, selection: selection) {
            ForEach(BellTone.allCases) { tone in
                Text(tone.label).tag(tone)
            }
        }
        .onChange(of: selection.wrappedValue) { _, new in
            BellPlayer.shared.play(new)
        }
    }

    private func load() {
        guard let preset else { return }
        name = preset.name
        minutes = preset.minutes
        warmup = preset.warmupSeconds
        intervalMinutes = preset.intervalMinutes
        startBell = preset.startBell
        intervalBell = preset.intervalBell
        endBell = preset.endBell
    }

    private func save() {
        guard canSave else { return }
        if let preset {
            preset.name = trimmedName
            preset.minutes = min(max(minutes, 1), 240)
            preset.warmupSeconds = min(max(warmup, 0), 120)
            preset.intervalMinutes = min(max(intervalMinutes, 0), 120)
            preset.startBell = startBell
            preset.intervalBell = intervalBell
            preset.endBell = endBell
        } else {
            let nextIndex = (allPresets.map(\.sortIndex).max() ?? -1) + 1
            let new = MeditationPreset(name: trimmedName, minutes: minutes,
                                       warmupSeconds: warmup, intervalMinutes: intervalMinutes,
                                       startBell: startBell, intervalBell: intervalBell,
                                       endBell: endBell, isBuiltIn: false, sortIndex: nextIndex)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
