import SwiftUI
import SwiftData

/// Create or edit a stash yarn.
struct YarnEditView: View {
    @Bindable var yarn: StashYarn
    var isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var yardsText = ""
    @State private var gramsText = ""

    private var trimmedName: String { yarn.name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Yarn") {
                    TextField("Name", text: $yarn.name)
                    TextField("Brand", text: $yarn.brand)
                    TextField("Colorway", text: $yarn.colorName)
                    TextField("Fiber", text: $yarn.fiber)
                    Picker("Weight", selection: Binding(get: { yarn.weight }, set: { yarn.weight = $0 })) {
                        ForEach(YarnWeight.allCases) { Text("\($0.name) — \($0.commonName)").tag($0) }
                    }
                }
                Section {
                    Stepper(value: $yarn.skeins, in: 0...999) {
                        HStack { Text("Skeins"); Spacer()
                            Text("\(yarn.skeins)").foregroundStyle(Brand.text2).font(Brand.mono(15)) }
                    }
                    HStack {
                        Text("Yards / skein"); Spacer()
                        TextField("0", text: $yardsText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90)
                    }
                    HStack {
                        Text("Grams / skein"); Spacer()
                        TextField("0", text: $gramsText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90)
                    }
                } header: {
                    Text("Quantity")
                } footer: {
                    if let yds = Double(yardsText.replacingOccurrences(of: ",", with: ".")), yds > 0 {
                        Text("Total: \(Int(yds * Double(yarn.skeins))) yd across \(yarn.skeins) skein\(yarn.skeins == 1 ? "" : "s").")
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $yarn.notes, axis: .vertical).lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Yarn" : "Edit Yarn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancel() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear {
                if yarn.yardsPerSkein > 0 { yardsText = trimmed(yarn.yardsPerSkein) }
                if yarn.gramsPerSkein > 0 { gramsText = trimmed(yarn.gramsPerSkein) }
            }
        }
    }

    private func trimmed(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(d) }

    private func save() {
        yarn.name = trimmedName
        yarn.yardsPerSkein = max(0, Double(yardsText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        yarn.gramsPerSkein = max(0, Double(gramsText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        try? context.save(); Haptics.success(); dismiss()
    }
    private func cancel() { if isNew { context.delete(yarn) }; dismiss() }
}
