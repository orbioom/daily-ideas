import SwiftUI

/// Configure a counter's name, step, starting value, and optional repeat block.
/// Works for both new counters (counter == nil) and editing existing ones.
struct CounterEditView: View {
    let counter: Counter?
    var onCommit: (Counter) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = "Rows"
    @State private var valueText = "0"
    @State private var stepText = "1"
    @State private var tracksRepeat = false
    @State private var repeatText = "8"

    private var isNew: Bool { counter == nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Counter") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Start at")
                        Spacer()
                        TextField("0", text: $valueText).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    HStack {
                        Text("Step")
                        Spacer()
                        TextField("1", text: $stepText).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).frame(width: 80)
                    }
                }
                Section {
                    Toggle("Track a repeat", isOn: $tracksRepeat.animation())
                    if tracksRepeat {
                        HStack {
                            Text("Rows per repeat")
                            Spacer()
                            TextField("8", text: $repeatText).keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing).frame(width: 80)
                        }
                    }
                } footer: {
                    Text("With a repeat set, the counter shows where you are inside each block (e.g. \"step 3 of 8\").")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Counter" : "Edit Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let c = counter else { return }
        name = c.name
        valueText = String(c.value)
        stepText = String(c.step)
        tracksRepeat = c.repeatLength > 0
        if c.repeatLength > 0 { repeatText = String(c.repeatLength) }
    }

    private func save() {
        let value = max(0, Int(valueText) ?? 0)
        let step = max(1, Int(stepText) ?? 1)
        let repeatLen = tracksRepeat ? max(1, Int(repeatText) ?? 1) : 0
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let target = counter ?? Counter()
        target.name = trimmed
        target.value = value
        target.step = step
        target.repeatLength = repeatLen
        onCommit(target)
        Haptics.success()
        dismiss()
    }
}
