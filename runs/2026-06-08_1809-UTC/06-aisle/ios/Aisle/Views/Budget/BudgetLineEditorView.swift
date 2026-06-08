import SwiftUI
import SwiftData

struct BudgetLineEditorView: View {
    enum Mode { case create, edit(BudgetLine) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: BudgetCategory = .venue
    @State private var estimatedText = ""
    @State private var actualText = ""
    @State private var paidText = ""
    @State private var vendor = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var notes = ""

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    private func num(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item (e.g. Reception venue)", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    TextField("Vendor (optional)", text: $vendor)
                }
                Section("Cost") {
                    money("Estimated", $estimatedText)
                    money("Actual", $actualText)
                    money("Paid so far", $paidText)
                }
                Section {
                    Toggle("Payment due date", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(1...4)
                }
                if case let .edit(l) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(l); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete item", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func money(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).frame(width: 120)
        }
    }

    private func load() {
        if case let .edit(l) = mode {
            title = l.title; category = l.category; vendor = l.vendor; notes = l.notes
            estimatedText = l.estimatedCost > 0 ? String(format: "%.2f", l.estimatedCost) : ""
            actualText = l.actualCost > 0 ? String(format: "%.2f", l.actualCost) : ""
            paidText = l.paidAmount > 0 ? String(format: "%.2f", l.paidAmount) : ""
            if let d = l.dueDate { hasDueDate = true; dueDate = d }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .create:
            context.insert(BudgetLine(title: trimmed, category: category,
                                      estimatedCost: num(estimatedText), actualCost: num(actualText),
                                      paidAmount: num(paidText), vendor: vendor,
                                      dueDate: hasDueDate ? dueDate : nil, notes: notes))
        case .edit(let l):
            l.title = trimmed; l.category = category
            l.estimatedCost = num(estimatedText); l.actualCost = num(actualText); l.paidAmount = num(paidText)
            l.vendor = vendor; l.dueDate = hasDueDate ? dueDate : nil; l.notes = notes
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
