import SwiftUI
import SwiftData

/// Add a deposit, record a withdrawal, or edit an existing contribution.
struct ContributionEditorView: View {
    enum Mode {
        case deposit(Goal)
        case withdrawal(Goal)
        case edit(Contribution)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    let mode: Mode

    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date.now
    @State private var isWithdrawal = false

    private var parsedAmount: Double? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    private var title: String {
        switch mode {
        case .deposit: return "Add Contribution"
        case .withdrawal: return "Record Withdrawal"
        case .edit: return "Edit Entry"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text(settings.currency.symbol)
                            .foregroundStyle(Theme.inkSoft)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(Theme.money(20))
                    }
                    Toggle("This is a withdrawal", isOn: $isWithdrawal)
                }
                Section("Date") {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                }
                Section("Note") {
                    TextField("Optional note", text: $note)
                        .font(Theme.rounded(16))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(parsedAmount == nil)
                }
            }
            .onAppear(perform: configure)
        }
    }

    private func configure() {
        switch mode {
        case .deposit:
            isWithdrawal = false
        case .withdrawal:
            isWithdrawal = true
        case .edit(let c):
            amountText = String(format: "%.2f", c.amount)
            note = c.note
            date = c.date
            isWithdrawal = c.isWithdrawal
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        switch mode {
        case .deposit(let goal), .withdrawal(let goal):
            let c = Contribution(date: date, amount: amount, isWithdrawal: isWithdrawal, note: note, goal: goal)
            goal.contributions.append(c)
        case .edit(let c):
            c.amount = abs(amount)
            c.note = note
            c.date = date
            c.isWithdrawal = isWithdrawal
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
