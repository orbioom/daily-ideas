import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var wedding: Wedding
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var tasks: [ChecklistTask]

    @AppStorage("aisle.haptics") private var haptics = true
    @State private var budgetText = ""
    @State private var showReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "MXN", "ZAR", "NGN"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Wedding") {
                    TextField("Couple names", text: $wedding.coupleNames)
                    DatePicker("Date", selection: $wedding.weddingDate, displayedComponents: .date)
                    TextField("Venue", text: $wedding.venue)
                    HStack {
                        Text("Total budget")
                        Spacer()
                        TextField("0", text: $budgetText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 120)
                    }
                    Picker("Currency", selection: $wedding.currencyCode) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section {
                    Button {
                        SeedData.seedChecklist(context, weddingDate: wedding.weddingDate)
                        Haptics.success()
                    } label: {
                        Label("Add standard checklist", systemImage: "checklist")
                    }
                    .disabled(!tasks.isEmpty)
                } footer: {
                    Text(tasks.isEmpty ? "Adds a typical 15-item planning timeline based on your date."
                                       : "You already have checklist items.")
                }

                Section("Feel") {
                    Toggle("Haptics", isOn: $haptics)
                        .onChange(of: haptics) { _, new in Haptics.enabled = new }
                }

                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Erase everything", systemImage: "trash")
                    }
                } footer: {
                    Text("Aisle keeps all your planning private to this device.")
                }

                Section { LabeledContent("Version", value: "1.0"); LabeledContent("Made by", value: "Orbioom") }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { commit(); dismiss() } }
            }
            .onAppear { if wedding.totalBudget > 0 { budgetText = String(format: "%.0f", wedding.totalBudget) } }
            .confirmationDialog("Erase everything?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Erase all", role: .destructive, action: resetAll)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This deletes the wedding and all guests, budget, tasks, and tables. This can't be undone.")
            }
        }
    }

    private func commit() {
        if let b = Double(budgetText.replacingOccurrences(of: ",", with: ".")), b >= 0 {
            wedding.totalBudget = b
        }
        try? context.save()
    }

    private func resetAll() {
        try? context.delete(model: Guest.self)
        try? context.delete(model: SeatingTable.self)
        try? context.delete(model: BudgetLine.self)
        try? context.delete(model: ChecklistTask.self)
        try? context.delete(model: Wedding.self)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
