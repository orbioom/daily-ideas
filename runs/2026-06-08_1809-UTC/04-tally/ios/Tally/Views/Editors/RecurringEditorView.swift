import SwiftUI
import SwiftData

struct RecurringEditorView: View {
    enum Mode { case create, edit(RecurringRule) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var isIncome = false
    @State private var amountText = ""
    @State private var category: Category = .housing
    @State private var dayOfMonth = 1
    @State private var isActive = true

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var categories: [Category] { isIncome ? Category.incomeCases : Category.expenseCases }
    private var amount: Double? {
        let v = Double(amountText.replacingOccurrences(of: ",", with: "."))
        guard let v, v > 0 else { return nil }
        return v
    }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && amount != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (e.g. Rent)", text: $title)
                    Picker("Type", selection: $isIncome) {
                        Text("Expense").tag(false); Text("Income").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isIncome) { _, _ in
                        if !categories.contains(category) { category = categories.first ?? .other }
                    }
                    TextField("Amount", text: $amountText).keyboardType(.decimalPad)
                }
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(categories) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    Picker("Day of month", selection: $dayOfMonth) {
                        ForEach(1...28, id: \.self) { Text(Format.ordinal($0)).tag($0) }
                    }
                    Toggle("Active", isOn: $isActive)
                }
                if case let .edit(r) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(r); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Recurring" : "New Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case let .edit(r) = mode {
            title = r.title; isIncome = r.isIncome
            amountText = String(format: "%.2f", r.amount)
            category = r.category; dayOfMonth = r.dayOfMonth; isActive = r.isActive
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, let amount else { return }
        if !categories.contains(category) { category = categories.first ?? .other }
        switch mode {
        case .create:
            let r = RecurringRule(title: t, amount: amount, category: category,
                                  isIncome: isIncome, dayOfMonth: dayOfMonth)
            r.isActive = isActive
            context.insert(r)
        case .edit(let r):
            r.title = t; r.amount = amount; r.category = category
            r.isIncome = isIncome; r.dayOfMonth = dayOfMonth; r.isActive = isActive
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
