import SwiftUI
import SwiftData

/// One debt: status, payment history, and logging.
struct DebtDetailView: View {
    @Bindable var debt: Debt
    @Environment(\.modelContext) private var context
    @AppStorage("currencyCode") private var currency = "USD"

    @State private var editing = false
    @State private var loggingPayment = false

    private var totalPaid: Double { debt.payments.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summary
                paymentsCard
            }
            .padding(.horizontal, 16).padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle(debt.name.isEmpty ? "Debt" : debt.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Image(systemName: "pencil") }.accessibilityLabel("Edit debt")
            }
        }
        .sheet(isPresented: $editing) { DebtEditView(debt: debt, isNew: false) }
        .sheet(isPresented: $loggingPayment) {
            PaymentEditView { amount, date, note in logPayment(amount, date, note) }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(debt.kind.label, systemImage: debt.kind.symbol).font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                if !debt.includeInPlan { Pill(text: "Excluded from plan", tint: Brand.text3) }
            }
            HStack(spacing: 10) {
                StatTile(value: Money.string(debt.balance, code: currency), label: "Balance", tint: Brand.text)
                StatTile(value: String(format: "%.2f%%", debt.apr), label: "APR", tint: Brand.warn)
            }
            HStack(spacing: 10) {
                StatTile(value: Money.string(debt.minPayment, code: currency), label: "Minimum")
                StatTile(value: Money.string(debt.monthlyInterest, code: currency, fraction: true), label: "Interest / mo", tint: Brand.danger)
            }
            Button { loggingPayment = true } label: { Label("Log a payment", systemImage: "plus.circle") }
                .buttonStyle(InkButtonStyle())
        }
        .glassCard()
    }

    private var paymentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "Payments")
                Spacer()
                Text("Total \(Money.string(totalPaid, code: currency))").font(.caption).foregroundStyle(Brand.text3)
            }
            if debt.payments.isEmpty {
                EmptyStateView(icon: "tray", title: "No payments logged",
                               message: "Logging payments lowers the balance and keeps a record here.")
            } else {
                ForEach(debt.orderedPayments) { p in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline).foregroundStyle(Brand.text)
                            if !p.note.isEmpty { Text(p.note).font(.caption).foregroundStyle(Brand.text3) }
                        }
                        Spacer()
                        Text("−\(Money.string(p.amount, code: currency))")
                            .font(Brand.mono(15, weight: .medium)).foregroundStyle(Brand.live)
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button(role: .destructive) { deletePayment(p) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .glassCard()
    }

    private func logPayment(_ amount: Double, _ date: Date, _ note: String) {
        let p = Payment(amount: amount, date: date, note: note)
        p.debt = debt
        debt.payments.append(p)
        debt.balance = max(0, debt.balance - amount)
        try? context.save(); Haptics.success()
    }
    private func deletePayment(_ p: Payment) {
        debt.balance += p.amount      // restore the balance the payment reduced
        context.delete(p)
        try? context.save(); Haptics.warning()
    }
}

/// Minimal payment entry sheet.
struct PaymentEditView: View {
    var onSave: (Double, Date, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currency = "USD"
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""

    private var canSave: Bool { (Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment") {
                    HStack {
                        Text("Amount"); Spacer()
                        TextField("0", text: $amountText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 120).font(Brand.mono(16))
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Log Payment").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(max(0, Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0), date, note.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }.disabled(!canSave).fontWeight(.semibold)
                }
            }
        }
    }
}
