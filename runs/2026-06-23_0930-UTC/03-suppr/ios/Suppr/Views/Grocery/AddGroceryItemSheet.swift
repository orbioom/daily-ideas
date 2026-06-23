import SwiftUI
import SwiftData

/// Add a manual grocery item that survives list regeneration.
struct AddGroceryItemSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = ""
    @State private var unit = ""
    @State private var aisle: Aisle = .produce
    @State private var showValidation = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    if showValidation && trimmedName.isEmpty {
                        Label("Enter a name.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(Theme.terracotta)
                    }
                    HStack {
                        TextField("Qty", text: $quantity)
                            .keyboardType(.decimalPad)
                        TextField("Unit (optional)", text: $unit)
                    }
                }
                Section("Aisle") {
                    Picker("Aisle", selection: $aisle) {
                        ForEach(Aisle.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard canSave else { showValidation = true; Haptics.warning(); return }
        let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 1
        PlanStore(context: context).addManualItem(
            name: trimmedName,
            quantity: max(0, qty),
            unit: unit.trimmingCharacters(in: .whitespaces),
            aisle: aisle
        )
        Haptics.success()
        dismiss()
    }
}
