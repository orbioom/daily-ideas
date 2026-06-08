import SwiftUI
import SwiftData

struct StepEditorView: View {
    // Create mode
    var routine: RoutineKind = .am
    var order: Int = 0
    // Edit mode
    var editing: RoutineStep?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Product.name) private var products: [Product]

    @State private var useProduct = true
    @State private var selectedProductID: PersistentIdentifier?
    @State private var customLabel = ""
    @State private var instruction = ""

    private var isEditing: Bool { editing != nil }
    private var activeProducts: [Product] { products.filter { !$0.isFinished } }
    private var canSave: Bool {
        useProduct ? selectedProductID != nil : !customLabel.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Step type", selection: $useProduct) {
                        Text("From shelf").tag(true)
                        Text("Custom").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                if useProduct {
                    Section("Product") {
                        if activeProducts.isEmpty {
                            Text("No products on your shelf yet. Add one in the Shelf tab, or use a custom step.")
                                .font(.caption).foregroundStyle(Brand.text3)
                        } else {
                            Picker("Product", selection: $selectedProductID) {
                                Text("Choose…").tag(PersistentIdentifier?.none)
                                ForEach(activeProducts) { p in
                                    Text(p.name).tag(p.persistentModelID as PersistentIdentifier?)
                                }
                            }
                        }
                    }
                } else {
                    Section("Custom step") {
                        TextField("Label (e.g. Face massage)", text: $customLabel)
                    }
                }
                Section("Note") {
                    TextField("Instruction (optional)", text: $instruction, axis: .vertical).lineLimit(1...3)
                }
                if let editing {
                    Section {
                        Button(role: .destructive) {
                            context.delete(editing); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Remove step", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Step" : "Add Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let editing {
            if let p = editing.product { useProduct = true; selectedProductID = p.persistentModelID }
            else { useProduct = false; customLabel = editing.customLabel }
            instruction = editing.instruction
        }
    }

    private func save() {
        let product = useProduct ? activeProducts.first { $0.persistentModelID == selectedProductID } : nil
        if let editing {
            editing.product = product
            editing.customLabel = useProduct ? "" : customLabel.trimmingCharacters(in: .whitespaces)
            editing.instruction = instruction
        } else {
            let step = RoutineStep(routine: routine, order: order, product: product,
                                   customLabel: useProduct ? "" : customLabel.trimmingCharacters(in: .whitespaces),
                                   instruction: instruction)
            context.insert(step)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
