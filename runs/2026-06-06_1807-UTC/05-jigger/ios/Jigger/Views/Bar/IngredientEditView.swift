import SwiftUI
import SwiftData

struct IngredientEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let ingredient: Ingredient?

    @State private var name = ""
    @State private var category = IngredientCategory.spirit
    @State private var inStock = true
    @State private var notes = ""
    @State private var confirmDelete = false

    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField("Name (e.g. Bourbon)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(IngredientCategory.allCases) {
                            Label($0.rawValue, systemImage: $0.icon).tag($0)
                        }
                    }
                    Toggle("In stock", isOn: $inStock)
                }
                Section("Notes") {
                    TextField("Brand, bottle, anything", text: $notes, axis: .vertical).lineLimit(1...4)
                }
                if let ing = ingredient, !ing.components.isEmpty {
                    Section {
                        Text("Used in \(ing.components.count) recipe line\(ing.components.count == 1 ? "" : "s").")
                            .font(.footnote).foregroundStyle(Brand.text2)
                    }
                }
                if ingredient != nil {
                    Section {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete ingredient", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(ingredient == nil ? "New Ingredient" : "Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
            .alert("Delete this ingredient?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let ing = ingredient { context.delete(ing); try? context.save(); Haptics.warning() }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Recipe lines that used it will show as missing.") }
        }
    }

    private func load() {
        guard let ing = ingredient else { return }
        name = ing.name; category = ing.category; inStock = ing.inStock; notes = ing.notes
    }
    private func save() {
        if let ing = ingredient {
            ing.name = name; ing.category = category; ing.inStock = inStock; ing.notes = notes
        } else {
            context.insert(Ingredient(name: name, category: category, inStock: inStock, notes: notes))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
