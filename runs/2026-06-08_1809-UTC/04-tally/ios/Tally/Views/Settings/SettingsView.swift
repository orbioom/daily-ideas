import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("tally.haptics") private var haptics = true
    @AppStorage("tally.defaultToIncome") private var defaultToIncome = false
    @State private var showReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "MXN", "ZAR", "NGN"]

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("New entries default to", selection: $defaultToIncome) {
                        Text("Expense").tag(false)
                        Text("Income").tag(true)
                    }
                    Toggle("Haptics", isOn: $haptics)
                        .onChange(of: haptics) { _, new in Haptics.enabled = new }
                }

                Section("Automation") {
                    NavigationLink {
                        RecurringView()
                    } label: {
                        Label("Recurring transactions", systemImage: "repeat")
                    }
                } footer: {
                    Text("Recurring bills and income post automatically each month on the day you choose.")
                }

                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Erase all data", systemImage: "trash")
                    }
                } footer: {
                    Text("Everything in Tally stays on this device. Nothing is uploaded or shared.")
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Made by", value: "Orbioom")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Erase everything?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Erase all", role: .destructive, action: resetAll)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This deletes every transaction, budget, and recurring item. This can't be undone.")
            }
        }
    }

    private func resetAll() {
        try? context.delete(model: Transaction.self)
        try? context.delete(model: BudgetItem.self)
        try? context.delete(model: RecurringRule.self)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
