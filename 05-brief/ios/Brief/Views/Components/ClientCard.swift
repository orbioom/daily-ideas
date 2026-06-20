import SwiftUI

struct ClientCard: View {
    let client: Client

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(BriefTheme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String(client.name.prefix(1)).uppercased())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(BriefTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                if !client.company.isEmpty {
                    Text(client.company)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if !client.email.isEmpty {
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if client.outstanding > Decimal(0) {
                    Text(formatCurrency(client.outstanding))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(BriefTheme.overdueColor)
                    Text("outstanding")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if client.totalBilled > Decimal(0) {
                    Text(formatCurrency(client.totalBilled))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("billed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(client.invoices.count) invoice\(client.invoices.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(client.name), \(client.company.isEmpty ? "" : client.company + ", ")\(client.outstanding > Decimal(0) ? formatCurrency(client.outstanding) + " outstanding" : "")")
    }
}
