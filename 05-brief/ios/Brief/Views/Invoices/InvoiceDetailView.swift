import SwiftUI
import SwiftData
import UIKit

struct InvoiceDetailView: View {
    let invoice: Invoice
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [BriefSettings]
    @State private var showingEditor = false
    @State private var showingStatusPicker = false
    @State private var showingShareSheet = false

    private var settings: BriefSettings? { settingsQuery.first }

    var body: some View {
        List {
            // Overdue banner
            if invoice.isOverdue {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Payment Overdue")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("This invoice was due \(abs(invoice.daysUntilDue)) days ago")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(BriefTheme.overdueColor)
                }
            }

            // Invoice header
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invoice.number.isEmpty ? "Draft Invoice" : invoice.number)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let clientName = invoice.client?.name {
                            Text(clientName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        showingStatusPicker = true
                    } label: {
                        StatusBadge(status: invoice.displayStatus)
                    }
                    .accessibilityLabel("Change invoice status, currently \(invoice.displayStatus.rawValue)")
                }
                .padding(.vertical, 4)

                HStack {
                    Label("Issued", systemImage: "calendar")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(invoice.issueDate, style: .date)
                }
                HStack {
                    Label("Due", systemImage: "calendar.badge.clock")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(invoice.dueDate, style: .date)
                        .foregroundColor(invoice.isOverdue ? BriefTheme.overdueColor : .primary)
                }
            }

            // Line items
            Section("Line Items") {
                let sorted = invoice.lineItems.sorted { $0.order < $1.order }
                if sorted.isEmpty {
                    Text("No line items")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(sorted) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemDescription.isEmpty ? "Untitled item" : item.itemDescription)
                                .font(.body)
                            HStack {
                                Text("\(formatDecimalDisplay(item.quantity)) × \(formatCurrency(item.unitPrice, code: invoice.currencyCode))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(item.subtotal, code: invoice.currencyCode))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            // Totals
            Section("Totals") {
                HStack {
                    Text("Subtotal")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(invoice.subtotal, code: invoice.currencyCode))
                }
                if invoice.discountAmount > Decimal(0) {
                    HStack {
                        Text("Discount")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("−\(formatCurrency(invoice.discountAmount, code: invoice.currencyCode))")
                            .foregroundColor(BriefTheme.paidColor)
                    }
                }
                if invoice.taxRate > Decimal(0) {
                    HStack {
                        Text("Tax (\(formatDecimalDisplay(invoice.taxRate * Decimal(100)))%)")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(invoice.taxAmount, code: invoice.currencyCode))
                    }
                }
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatCurrency(invoice.total, code: invoice.currencyCode))
                        .fontWeight(.bold)
                        .font(.title3)
                }
            }

            // Notes
            if !invoice.notes.isEmpty {
                Section("Notes") {
                    Text(invoice.notes)
                        .foregroundColor(.secondary)
                }
            }

            // Actions
            Section("Actions") {
                Button {
                    sharePDF()
                } label: {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Share invoice as PDF")

                if invoice.status != .paid {
                    Button {
                        markAsPaid()
                    } label: {
                        Label("Mark as Paid", systemImage: "checkmark.seal.fill")
                            .foregroundColor(BriefTheme.paidColor)
                    }
                    .accessibilityLabel("Mark invoice as paid")
                }

                Button {
                    duplicateInvoice()
                } label: {
                    Label("Duplicate Invoice", systemImage: "doc.on.doc")
                }
                .accessibilityLabel("Duplicate this invoice")

                Button {
                    showingEditor = true
                } label: {
                    Label("Edit Invoice", systemImage: "pencil")
                }
                .accessibilityLabel("Edit invoice")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(invoice.number.isEmpty ? "Invoice" : invoice.number)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditor) {
            InvoiceEditorView(invoice: invoice)
        }
        .confirmationDialog(
            "Change Status",
            isPresented: $showingStatusPicker,
            titleVisibility: .visible
        ) {
            ForEach(InvoiceStatus.allCases, id: \.self) { status in
                Button(status.rawValue) {
                    invoice.status = status
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func markAsPaid() {
        invoice.status = .paid
        try? modelContext.save()
    }

    private func duplicateInvoice() {
        let copy = Invoice()
        copy.client = invoice.client
        copy.notes = invoice.notes
        copy.taxRate = invoice.taxRate
        copy.discountAmount = invoice.discountAmount
        copy.currencyCode = invoice.currencyCode
        copy.status = .draft

        if let settings = settings {
            copy.number = settings.nextNumber()
        } else {
            copy.number = "COPY-\(invoice.number)"
        }

        let copiedItems = invoice.lineItems.map { item in
            let newItem = LineItem(order: item.order, description: item.itemDescription, quantity: item.quantity, unitPrice: item.unitPrice)
            return newItem
        }
        copy.lineItems = copiedItems

        modelContext.insert(copy)
        try? modelContext.save()
    }

    private func sharePDF() {
        let s = settings ?? BriefSettings()
        let data = InvoicePDFRenderer.generatePDF(invoice: invoice, settings: s)
        let filename = invoice.number.isEmpty ? "invoice.pdf" : "\(invoice.number).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let root = window.rootViewController {
                var presented = root
                while let next = presented.presentedViewController {
                    presented = next
                }
                av.popoverPresentationController?.sourceView = window
                presented.present(av, animated: true)
            }
        } catch {
            // silently fail — in production would show an alert
        }
    }

    private func formatDecimalDisplay(_ value: Decimal) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 2
        fmt.minimumFractionDigits = 0
        return fmt.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
