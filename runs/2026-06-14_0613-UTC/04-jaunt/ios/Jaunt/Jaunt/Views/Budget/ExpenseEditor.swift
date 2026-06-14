import SwiftUI
import SwiftData

struct ExpenseEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Bindable var trip: Trip
    let expense: Expense?

    @State private var title = ""
    @State private var amount = ""
    @State private var category: ItemCategory = .food
    @State private var date = Date()
    @State private var showValidation = false

    private var isEditing: Bool { expense != nil }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var amountValue: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var valid: Bool { !trimmedTitle.isEmpty && amountValue > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense") {
                    TextField("What was it? (e.g. Dinner)", text: $title)
                    HStack {
                        Text(settings.currencySymbol)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { c in
                            Label(c.label, systemImage: c.symbol).tag(c)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                if showValidation && !valid {
                    Section {
                        Label("Add a title and an amount above zero.", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.danger)
                    }
                }
                if isEditing {
                    Section {
                        Button(role: .destructive) { remove() } label: {
                            Label("Delete expense", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        date = trip.startDate
        guard let expense else { return }
        title = expense.title
        amount = expense.amount > 0 ? numberString(expense.amount) : ""
        category = expense.category
        date = expense.date
    }

    private func save() {
        guard valid else {
            showValidation = true
            Haptics.warning()
            return
        }
        if let expense {
            expense.title = trimmedTitle
            expense.amount = amountValue
            expense.category = category
            expense.date = date
        } else {
            let e = Expense(title: trimmedTitle, category: category, amount: amountValue, date: date)
            context.insert(e)
            e.trip = trip
        }
        Haptics.success()
        dismiss()
    }

    private func remove() {
        guard let expense else { return }
        Haptics.tap()
        context.delete(expense)
        dismiss()
    }

    private func numberString(_ value: Double) -> String {
        let r = value.rounded()
        return abs(value - r) < 0.005 ? String(format: "%.0f", r) : String(format: "%.2f", value)
    }
}
