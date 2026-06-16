import SwiftUI
import SwiftData

struct RentPaymentSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let row: RentRollRow
    var onResult: (String) -> Void

    @State private var partialAmount = ""
    @State private var showPartialField = false

    private var payment: RentPayment { row.payment }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summary
                    actions
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("Rent Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var summary: some View {
        VStack(spacing: 12) {
            Text(row.tenantName)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text("\(row.propertyName) · \(row.unitLabel)")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)

            DetailRow(label: "Due date", value: DateText.full(payment.dueDate))
            DetailRow(label: "Amount due", value: Money.format(payment.amountDue, currencyCode: settings.currencyCode))
            DetailRow(label: "Amount paid", value: Money.format(payment.amountPaid, currencyCode: settings.currencyCode))
            DetailRow(
                label: "Outstanding",
                value: Money.format(payment.outstanding, currencyCode: settings.currencyCode),
                valueColor: payment.outstanding > 0 ? Theme.bad : Theme.good
            )
            HStack {
                Text("Status").font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                Spacer()
                StatusChip(text: payment.status.rawValue, color: payment.status.color, systemImage: payment.status.systemImage)
            }
        }
        .cardSurface()
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                markPaid()
            } label: {
                Label("Mark fully paid", systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                    .foregroundStyle(.white)
            }

            Button {
                withAnimation { showPartialField.toggle() }
            } label: {
                Label("Record partial payment", systemImage: "circle.lefthalf.filled")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                    .foregroundStyle(Theme.ink)
            }

            if showPartialField {
                HStack {
                    Text("Amount").foregroundStyle(Theme.ink)
                    Spacer()
                    TextField("0", text: $partialAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140)
                        .accessibilityLabel("Partial amount")
                }
                .cardSurface()
                Button("Save partial") { recordPartial() }
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
            }

            if payment.amountPaid > 0 {
                Button(role: .destructive) {
                    reset()
                } label: {
                    Label("Reset to unpaid", systemImage: "arrow.uturn.backward")
                        .font(Theme.rounded(15, .medium))
                }
                .padding(.top, 4)
            }
        }
    }

    private func parse(_ text: String) -> Decimal {
        Decimal(string: text.filter { $0.isNumber || $0 == "." }) ?? 0
    }

    private func markPaid() {
        payment.amountPaid = payment.amountDue
        payment.paidDate = Date()
        payment.reclassify()
        persist("Marked paid")
    }

    private func recordPartial() {
        let value = parse(partialAmount)
        guard value > 0 else { return }
        payment.amountPaid = min(value, payment.amountDue)
        payment.paidDate = Date()
        payment.reclassify()
        persist("Partial payment saved")
    }

    private func reset() {
        payment.amountPaid = 0
        payment.paidDate = nil
        payment.reclassify()
        persist("Reset to unpaid")
    }

    private func persist(_ message: String) {
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        onResult(message)
        dismiss()
    }
}
