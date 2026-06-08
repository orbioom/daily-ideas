import SwiftUI
import SwiftData

struct BudgetEditorView: View {
    // Edit existing, or create with a list of available categories.
    var budget: BudgetItem?
    var availableCategories: [Category] = []

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var category: Category = .groceries
    @State private var limitText = ""

    private var isEditing: Bool { budget != nil }
    private var limit: Double? {
        let v = Double(limitText.replacingOccurrences(of: ",", with: "."))
        guard let v, v >= 0 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    if isEditing {
                        Label(category.title, systemImage: category.icon)
                    } else {
                        Picker("Category", selection: $category) {
                            ForEach(availableCategories) { Label($0.title, systemImage: $0.icon).tag($0) }
                        }
                    }
                }
                Section("Monthly limit") {
                    TextField("0", text: $limitText).keyboardType(.decimalPad).font(.title3)
                }
                if let budget {
                    Section {
                        Button(role: .destructive) {
                            context.delete(budget); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Remove budget", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? category.title : "New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(limit == nil) }
            }
            .onAppear {
                if let budget {
                    category = budget.category
                    limitText = String(format: "%.0f", budget.monthlyLimit)
                } else {
                    category = availableCategories.first ?? .groceries
                }
            }
        }
    }

    private func save() {
        guard let limit else { return }
        if let budget {
            budget.monthlyLimit = limit
        } else {
            context.insert(BudgetItem(category: category, monthlyLimit: limit))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
