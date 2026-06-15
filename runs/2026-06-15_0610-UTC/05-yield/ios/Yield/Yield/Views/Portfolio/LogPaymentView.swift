import SwiftUI
import SwiftData

/// Log a historical dividend payment for a holding. Defaults are pre-filled from the holding.
struct LogPaymentView: View {
    let holding: Holding
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var payDate = Date()
    @State private var amountText = ""
    @State private var sharesText = ""
    @State private var reinvested = true
    @State private var didPrefill = false

    private var amountValue: Decimal? { HoldingFormView.parse(amountText) }
    private var sharesValue: Decimal? { HoldingFormView.parse(sharesText) }
    private var canSave: Bool { (amountValue ?? -1) >= 0 && (sharesValue ?? 0) > 0 }

    private var total: Decimal {
        max(amountValue ?? 0, 0) * max(sharesValue ?? 0, 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Pay date", selection: $payDate, displayedComponents: .date)
                    field("Amount / share", text: $amountText, placeholder: "0.50")
                    field("Shares at payment", text: $sharesText, placeholder: MoneyFormat.shares(holding.shares))
                    Toggle("Reinvested (DRIP)", isOn: $reinvested)
                } header: {
                    Text("Payment for \(holding.ticker)")
                } footer: {
                    Text("Total: \(MoneyFormat.currency(total, code: settings.currencyCode))")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Log Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
        }
    }

    private func prefill() {
        guard !didPrefill else { return }
        didPrefill = true
        sharesText = MoneyFormat.shares(holding.shares)
        let per = IncomeEngine.perPaymentIncome(for: holding)
        let perShare = holding.shares > 0 ? per / holding.shares : 0
        amountText = NSDecimalNumber(decimal: perShare).stringValue
    }

    private func save() {
        guard let amount = amountValue, let shares = sharesValue, shares > 0 else { return }
        let payment = DividendPayment(payDate: payDate,
                                      amountPerShare: amount,
                                      sharesAtPayment: shares,
                                      reinvested: reinvested,
                                      holding: holding)
        context.insert(payment)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
