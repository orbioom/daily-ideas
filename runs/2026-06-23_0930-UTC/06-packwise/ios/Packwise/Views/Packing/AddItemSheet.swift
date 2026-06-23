import SwiftUI

/// A sheet to add a custom item to a packing list or template.
struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, Int, PackCategory) -> Void

    @State private var name = ""
    @State private var quantity = 1
    @State private var category: PackCategory = .clothing

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item name", text: $name)
                        .textInputAutocapitalization(.sentences)
                    Stepper(value: $quantity, in: 1...99) {
                        Text("Quantity: \(quantity)")
                            .monospacedDigit()
                    }
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(PackCategory.allCases) { cat in
                            Label(cat.title, systemImage: cat.symbol).tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Add item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        onAdd(trimmed, quantity, category)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
