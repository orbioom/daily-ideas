import SwiftUI
import SwiftData

/// A sheet to log a spend against a gift card. Validates the amount can't exceed the
/// remaining balance and shows the resulting balance live.
struct LogSpendView: View {
    @Bindable var card: GiftCard
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()

    private var parsedAmount: Decimal? { Money.parse(amountText) }

    private var exceedsBalance: Bool {
        guard let amount = parsedAmount else { return false }
        return amount > card.remainingBalance
    }

    private var canSave: Bool {
        guard let amount = parsedAmount else { return false }
        return amount > 0 && !exceedsBalance
    }

    private var resultingBalance: Decimal {
        guard let amount = parsedAmount else { return card.remainingBalance }
        let result = card.remainingBalance - amount
        return result < 0 ? 0 : result
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.mono(17, .medium))
                    }
                    TextField("Note (optional)", text: $note)
                        .textInputAutocapitalization(.sentences)
                    DatePicker("Date", selection: $date,
                               in: ...Date(), displayedComponents: .date)
                } header: {
                    Text("Log a spend")
                } footer: {
                    if exceedsBalance {
                        Text("That's more than the \(Money.string(card.remainingBalance, code: card.currencyCode)) remaining on this card.")
                            .foregroundStyle(Theme.warn)
                    } else {
                        Text("Spending against \(card.storeName).")
                    }
                }

                Section {
                    HStack {
                        Text("Remaining after")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Text(Money.string(resultingBalance, code: card.currencyCode))
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(resultingBalance <= 0 ? Theme.bad : Theme.ink)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Spend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(Theme.rounded(16, .semibold))
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let amount = parsedAmount, amount > 0, !exceedsBalance else { return }
        let tx = BalanceTransaction(amount: amount,
                                    note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                                    date: date,
                                    giftCard: card)
        context.insert(tx)
        card.transactions.append(tx)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
