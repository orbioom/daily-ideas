import SwiftUI
import SwiftData

/// Create a new account (name, type, starting balance, on/off budget).
struct AddAccountSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var name = ""
    @State private var type: AccountType = .checking
    @State private var balanceText = ""
    @State private var onBudget = true

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var parsedBalance: Double {
        let cleaned = balanceText.replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value.isFinite else { return 0 }
        return BudgetEngine.cents(value)
    }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Name (e.g. Everyday Checking)", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases) { t in
                            Label(t.label, systemImage: t.symbol).tag(t)
                        }
                    }
                    Toggle("Include in budget", isOn: $onBudget)
                }

                Section {
                    HStack {
                        Text(settings.currencySymbol)
                            .font(Theme.money(18, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        TextField("0.00", text: $balanceText)
                            .keyboardType(type == .creditCard ? .numbersAndPunctuation : .decimalPad)
                            .font(Theme.money(20, .semibold))
                            .monospacedDigit()
                    }
                } header: {
                    Text("Starting balance")
                } footer: {
                    Text(type == .creditCard
                         ? "For a credit card, enter what you currently owe as a negative number (e.g. -250)."
                         : "The amount currently in this account.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let account = Account(name: trimmedName, type: type, onBudget: onBudget, startingBalance: parsedBalance)
        context.insert(account)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
