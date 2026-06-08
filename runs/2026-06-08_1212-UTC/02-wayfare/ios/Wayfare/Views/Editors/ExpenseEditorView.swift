import SwiftUI
import SwiftData

struct ExpenseEditorView: View {
    @Bindable var expense: Expense
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        TextField("Title", text: $expense.title)
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("0", value: $expense.amount, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 140)
                        }
                        Picker("Category", selection: Binding(
                            get: { expense.category },
                            set: { expense.category = $0 }
                        )) {
                            ForEach(ActivityCategory.allCases) { c in
                                Label(c.label, systemImage: c.symbol).tag(c)
                            }
                        }
                        DatePicker("Date", selection: $expense.date, displayedComponents: .date)
                    }
                    Section {
                        Button(role: .destructive) {
                            context.delete(expense); Haptics.warning(); dismiss()
                        } label: {
                            Label("Delete expense", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if expense.amount == 0 && expense.title.trimmingCharacters(in: .whitespaces).isEmpty {
                            context.delete(expense)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { save() }.fontWeight(.semibold)
                        .disabled(expense.amount <= 0)
                }
            }
        }
    }

    private func save() {
        if expense.title.trimmingCharacters(in: .whitespaces).isEmpty {
            expense.title = expense.category.label
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
