import SwiftUI
import SwiftData

/// Edit an existing step or add a new one to a bake's timeline. Duration is entered in
/// hours and minutes and stored as total minutes (clamped ≥ 0).
struct StepEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The step being edited, or nil to add a new one to `bake`.
    var step: BakeStep?
    /// Required when adding a new step.
    var bake: Bake?
    var nextOrder: Int = 0

    @State private var kind: StepKind = .bulk
    @State private var label: String = ""
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var detail: String = ""
    @State private var loaded = false

    private var totalMinutes: Int { max(0, hours * 60 + minutes) }

    private var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Step") {
                    Picker("Kind", selection: $kind) {
                        ForEach(StepKind.allCases) { k in
                            Label(k.title, systemImage: k.symbol).tag(k)
                        }
                    }
                    TextField(kind.title, text: $label)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Duration") {
                    Stepper(value: $hours, in: 0...48) {
                        HStack {
                            Text("Hours")
                            Spacer()
                            Text("\(hours)").font(Brand.mono(15)).monospacedDigit()
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    Stepper(value: $minutes, in: 0...59, step: 5) {
                        HStack {
                            Text("Minutes")
                            Spacer()
                            Text("\(minutes)").font(Brand.mono(15)).monospacedDigit()
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(BakersMath.durationString(minutes: totalMinutes))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                            .monospacedDigit()
                    }
                }

                Section("Detail") {
                    TextField("Optional note", text: $detail, axis: .vertical)
                        .lineLimit(1...4)
                }

                if step != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteStep()
                        } label: {
                            Label("Delete step", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(step == nil ? "Add Step" : "Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if let step {
            kind = step.kind
            label = step.label
            hours = max(0, step.plannedMinutes) / 60
            minutes = max(0, step.plannedMinutes) % 60
            detail = step.detail
        } else {
            kind = .bulk
            let def = kind.defaultMinutes
            hours = def / 60
            minutes = def % 60
        }
    }

    private func save() {
        let finalLabel = trimmedLabel.isEmpty ? kind.title : trimmedLabel
        if let step {
            step.kind = kind
            step.label = finalLabel
            step.plannedMinutes = totalMinutes
            step.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let bake {
            let new = BakeStep(order: nextOrder, kind: kind, label: finalLabel,
                               plannedMinutes: totalMinutes,
                               detail: detail.trimmingCharacters(in: .whitespacesAndNewlines))
            new.bake = bake
            context.insert(new)
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func deleteStep() {
        guard let step else { return }
        context.delete(step)
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
