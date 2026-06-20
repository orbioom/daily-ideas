import SwiftUI
import SwiftData

struct ClientDetailView: View {
    let client: Client
    @State private var showingEditor = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section("Contact") {
                if !client.company.isEmpty {
                    LabeledRow(label: "Company", value: client.company, icon: "building.2")
                }
                if !client.email.isEmpty {
                    LabeledRow(label: "Email", value: client.email, icon: "envelope")
                }
                if !client.phone.isEmpty {
                    LabeledRow(label: "Phone", value: client.phone, icon: "phone")
                }
                if !client.address.isEmpty {
                    LabeledRow(label: "Address", value: client.address, icon: "map")
                }
                if !client.notes.isEmpty {
                    LabeledRow(label: "Notes", value: client.notes, icon: "note.text")
                }
            }

            Section("Financials") {
                FinancialRow(label: "Total Billed", amount: client.totalBilled, color: .primary)
                FinancialRow(label: "Total Paid", amount: client.totalPaid, color: BriefTheme.paidColor)
                FinancialRow(label: "Outstanding", amount: client.outstanding,
                            color: client.outstanding > Decimal(0) ? BriefTheme.overdueColor : .secondary)
            }

            if !client.invoices.isEmpty {
                Section("Invoices (\(client.invoices.count))") {
                    ForEach(client.invoices.sorted(by: { $0.issueDate > $1.issueDate })) { invoice in
                        NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                            InvoiceCard(invoice: invoice)
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditor = true
                }
                .accessibilityLabel("Edit client")
            }
        }
        .sheet(isPresented: $showingEditor) {
            ClientEditorView(client: client)
        }
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct FinancialRow: View {
    let label: String
    let amount: Decimal
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(formatCurrency(amount))
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}
