import SwiftUI
import SwiftData

/// Sheet for adding a custom pantry item, with an aisle guess.
struct AddPantryItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var name = ""
    @State private var aisle: Aisle = .other
    @State private var inStock = true
    @State private var note = ""
    @State private var aisleEditedManually = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField("Name (e.g. Garlic)", text: $name)
                        .onChange(of: name) { _, newValue in
                            guard !aisleEditedManually else { return }
                            let guess = Aisle.guess(from: newValue)
                            if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                aisle = guess
                            }
                        }
                    Picker(selection: $aisle) {
                        ForEach(Aisle.allCases) { a in
                            Label(a.rawValue, systemImage: a.symbol).tag(a)
                        }
                    } label: {
                        Label("Aisle", systemImage: "square.grid.2x2")
                    }
                    .onChange(of: aisle) { _, _ in aisleEditedManually = true }
                }

                Section {
                    Toggle(isOn: $inStock) {
                        Label("In stock now", systemImage: "checkmark.circle")
                    }
                    TextField("Note (optional)", text: $note)
                } footer: {
                    Text("Aisle is guessed from the name — adjust it any time.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let item = PantryItem(name: trimmedName,
                              aisle: aisle,
                              inStock: inStock,
                              note: note.trimmingCharacters(in: .whitespaces))
        context.insert(item)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
