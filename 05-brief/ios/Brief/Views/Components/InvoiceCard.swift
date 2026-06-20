import SwiftUI

struct InvoiceCard: View {
    let invoice: Invoice

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(invoice.number.isEmpty ? "Draft" : invoice.number)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let clientName = invoice.client?.name, !clientName.isEmpty {
                        Text(clientName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                StatusBadge(status: invoice.displayStatus)
            }

            HStack {
                Text(formatCurrency(invoice.total, code: invoice.currencyCode))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Due \(invoice.dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(invoice.isOverdue ? BriefTheme.overdueColor : .secondary)
                    if invoice.isOverdue {
                        Text("\(abs(invoice.daysUntilDue))d overdue")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(BriefTheme.overdueColor)
                    } else if invoice.status != .paid && invoice.daysUntilDue <= 7 && invoice.daysUntilDue >= 0 {
                        Text("\(invoice.daysUntilDue)d left")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Invoice \(invoice.number), \(formatCurrency(invoice.total, code: invoice.currencyCode)), \(invoice.displayStatus.rawValue)")
    }
}
