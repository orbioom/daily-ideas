import SwiftUI
import SwiftData

struct LogPaymentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Debt.sortIndex) private var debts: [Debt]
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("celebrateMilestones") private var celebrate = true

    @State private var selectedID: UUID?
    @State private var amount: String = ""
    @State private var date = Date()

    private var openDebts: [Debt] { debts.filter { $0.balance > 0.005 } }
    private var selected: Debt? { debts.first { $0.id == selectedID } }
    private var amountValue: Double { Double(amount) ?? -1 }
    private var isValid: Bool { selected != nil && amountValue > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section("Which debt") {
                        if openDebts.isEmpty {
                            Text("Every debt is paid off — nothing left to log. 🎉")
                                .foregroundStyle(Theme.good)
                        } else {
                            Picker("Debt", selection: $selectedID) {
                                ForEach(openDebts) { d in
                                    Text("\(d.name) · \(Money.format(d.balance, code: currencyCode))").tag(Optional(d.id))
                                }
                            }
                        }
                    }
                    Section("Payment") {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("0", text: $amount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 120)
                        }
                        DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                        if let s = selected, amountValue > s.balance {
                            Text("That’s more than the balance — we’ll clear it to zero and mark it paid off.")
                                .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.good)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid).bold() }
            }
            .onAppear { if selectedID == nil { selectedID = openDebts.first?.id } }
        }
    }

    private func save() {
        guard let debt = selected, amountValue > 0 else { return }
        let applied = min(amountValue, debt.balance)
        debt.balance = max(0, debt.balance - applied)
        let log = PaymentLog(debtID: debt.id, debtName: debt.name,
                             amount: applied, balanceAfter: debt.balance, date: date)
        context.insert(log)
        try? context.save()
        if debt.balance <= 0.005 && celebrate { Haptics.success() } else { Haptics.tap() }
        dismiss()
    }
}
