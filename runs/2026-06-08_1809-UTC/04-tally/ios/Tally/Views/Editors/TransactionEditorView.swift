import SwiftUI
import SwiftData

struct TransactionEditorView: View {
    enum Mode { case create, edit(Transaction) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("tally.defaultToIncome") private var defaultToIncome = false

    @State private var isIncome = false
    @State private var amountText = ""
    @State private var category: Category = .groceries
    @State private var note = ""
    @State private var date = Date()

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var amount: Double? {
        let v = Double(amountText.replacingOccurrences(of: ",", with: "."))
        guard let v, v > 0 else { return nil }
        return v
    }
    private var categories: [Category] { isIncome ? Category.incomeCases : Category.expenseCases }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $isIncome) {
                        Text("Expense").tag(false)
                        Text("Income").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isIncome) { _, _ in
                        if !categories.contains(category) { category = categories.first ?? .other }
                    }

                    HStack {
                        Text(currencySymbol).foregroundStyle(Brand.text2)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories) { c in
                            Label(c.title, systemImage: c.icon).tag(c)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    TextField("Note (optional)", text: $note)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                if case let .edit(t) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(t); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit" : (isIncome ? "Add Income" : "Add Expense"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(amount == nil) }
            }
            .onAppear(perform: load)
        }
    }

    private var currencySymbol: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency
        return f.currencySymbol ?? "$"
    }

    private func load() {
        switch mode {
        case .create:
            isIncome = defaultToIncome
            category = categories.first ?? .groceries
        case .edit(let t):
            isIncome = t.isIncome
            amountText = String(format: "%.2f", t.amount)
            category = t.category
            note = t.note
            date = t.date
        }
    }

    private func save() {
        guard let amount else { return }
        if !categories.contains(category) { category = categories.first ?? .other }
        switch mode {
        case .create:
            context.insert(Transaction(date: date, amount: amount, category: category,
                                       note: note, isIncome: isIncome))
        case .edit(let t):
            t.amount = (amount * 100).rounded() / 100
            t.category = category
            t.note = note
            t.date = date
            t.isIncome = isIncome
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
