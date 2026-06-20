import SwiftUI
import SwiftData

struct InvoiceEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var settingsQuery: [BriefSettings]

    let invoice: Invoice?

    @State private var selectedClient: Client?
    @State private var invoiceNumber = ""
    @State private var issueDate = Date()
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var lineItems: [LineItemDraft] = []
    @State private var taxRate: Decimal = Decimal(0)
    @State private var discountAmount: Decimal = Decimal(0)
    @State private var notes = ""
    @State private var currencyCode = "USD"
    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var settings: BriefSettings? { settingsQuery.first }

    private let paymentTermOptions = [15, 30, 45, 60]
    private let currencyOptions = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CHF", "INR"]

    var subtotal: Decimal {
        lineItems.reduce(Decimal(0)) { $0 + $1.subtotal }
    }

    var taxAmount: Decimal {
        (subtotal - discountAmount) * taxRate
    }

    var total: Decimal {
        max(Decimal(0), subtotal - discountAmount + taxAmount)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Client
                Section("Client") {
                    if clients.isEmpty {
                        Text("No clients available. Add a client first.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Client", selection: $selectedClient) {
                            Text("Select a client").tag(Optional<Client>.none)
                            ForEach(clients) { client in
                                Text(client.name).tag(Optional(client))
                            }
                        }
                        .accessibilityLabel("Select client")
                    }
                }

                // Invoice details
                Section("Invoice Details") {
                    HStack {
                        Text("Number")
                        Spacer()
                        TextField("INV-1001", text: $invoiceNumber)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Invoice number")
                    }

                    DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                        .accessibilityLabel("Issue date")

                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .accessibilityLabel("Due date")

                    HStack {
                        Text("Due in")
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(paymentTermOptions, id: \.self) { days in
                                Button("\(days)d") {
                                    dueDate = Calendar.current.date(byAdding: .day, value: days, to: issueDate) ?? dueDate
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(6)
                                .accessibilityLabel("Set due date to \(days) days from issue date")
                            }
                        }
                    }

                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencyOptions, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .accessibilityLabel("Currency")
                }

                // Line items
                Section {
                    ForEach($lineItems) { $item in
                        LineItemRow(item: $item, currencyCode: currencyCode)
                    }
                    .onDelete { offsets in
                        lineItems.remove(atOffsets: offsets)
                    }

                    Button {
                        lineItems.append(LineItemDraft(order: lineItems.count))
                    } label: {
                        Label("Add Line Item", systemImage: "plus.circle.fill")
                            .foregroundColor(BriefTheme.accent)
                    }
                    .accessibilityLabel("Add line item")
                } header: {
                    Text("Line Items")
                } footer: {
                    if showValidationError && lineItems.isEmpty {
                        Text(validationMessage)
                            .foregroundColor(.red)
                    }
                }

                // Pricing
                Section("Pricing") {
                    CurrencyField(label: "Discount", value: $discountAmount, currencyCode: currencyCode)
                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        TextField("0", text: Binding(
                            get: {
                                let pct = taxRate * Decimal(100)
                                let fmt = NumberFormatter()
                                fmt.numberStyle = .decimal
                                fmt.maximumFractionDigits = 2
                                return fmt.string(from: pct as NSDecimalNumber) ?? "0"
                            },
                            set: { val in
                                let cleaned = val.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                                if let pct = Decimal(string: cleaned) {
                                    taxRate = pct / Decimal(100)
                                }
                            }
                        ))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Tax rate percentage")
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }

                // Totals summary
                Section("Summary") {
                    HStack {
                        Text("Subtotal")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(subtotal, code: currencyCode))
                    }
                    if discountAmount > Decimal(0) {
                        HStack {
                            Text("Discount")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("−\(formatCurrency(discountAmount, code: currencyCode))")
                                .foregroundColor(BriefTheme.paidColor)
                        }
                    }
                    if taxRate > Decimal(0) {
                        HStack {
                            Text("Tax")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(taxAmount, code: currencyCode))
                        }
                    }
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(formatCurrency(total, code: currencyCode))
                            .fontWeight(.bold)
                    }
                }

                // Notes
                Section("Notes") {
                    TextField("Payment instructions, thank you note, etc.", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .accessibilityLabel("Invoice notes")
                }
            }
            .navigationTitle(invoice == nil ? "New Invoice" : "Edit Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(invoice == nil ? "Create" : "Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel(invoice == nil ? "Create invoice" : "Save changes")
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        if let invoice {
            selectedClient = invoice.client
            invoiceNumber = invoice.number
            issueDate = invoice.issueDate
            dueDate = invoice.dueDate
            taxRate = invoice.taxRate
            discountAmount = invoice.discountAmount
            notes = invoice.notes
            currencyCode = invoice.currencyCode
            lineItems = invoice.lineItems.sorted { $0.order < $1.order }.map {
                LineItemDraft(order: $0.order, description: $0.itemDescription, quantity: $0.quantity, unitPrice: $0.unitPrice)
            }
        } else {
            if let settings {
                currencyCode = settings.defaultCurrency
                taxRate = settings.defaultTaxRate
                invoiceNumber = settings.nextNumber()
                dueDate = Calendar.current.date(byAdding: .day, value: settings.defaultPaymentTerms, to: issueDate) ?? dueDate
            }
        }
    }

    private func save() {
        let validItems = lineItems.filter { !$0.description.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !validItems.isEmpty else {
            showValidationError = true
            validationMessage = "Add at least one line item with a description."
            return
        }

        if let invoice {
            invoice.client = selectedClient
            invoice.number = invoiceNumber
            invoice.issueDate = issueDate
            invoice.dueDate = dueDate
            invoice.taxRate = taxRate
            invoice.discountAmount = discountAmount
            invoice.notes = notes
            invoice.currencyCode = currencyCode

            // Remove old items and replace
            for item in invoice.lineItems {
                modelContext.delete(item)
            }
            invoice.lineItems = validItems.enumerated().map { idx, draft in
                LineItem(order: idx, description: draft.description, quantity: draft.quantity, unitPrice: draft.unitPrice)
            }
        } else {
            let newInvoice = Invoice(number: invoiceNumber, issueDate: issueDate, dueDate: dueDate)
            newInvoice.client = selectedClient
            newInvoice.taxRate = taxRate
            newInvoice.discountAmount = discountAmount
            newInvoice.notes = notes
            newInvoice.currencyCode = currencyCode
            newInvoice.lineItems = validItems.enumerated().map { idx, draft in
                LineItem(order: idx, description: draft.description, quantity: draft.quantity, unitPrice: draft.unitPrice)
            }
            modelContext.insert(newInvoice)
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Draft types
struct LineItemDraft: Identifiable {
    var id = UUID()
    var order: Int
    var description: String = ""
    var quantity: Decimal = Decimal(1)
    var unitPrice: Decimal = Decimal(0)

    var subtotal: Decimal { quantity * unitPrice }
}

private struct LineItemRow: View {
    @Binding var item: LineItemDraft
    let currencyCode: String

    @State private var qtyText: String = ""
    @State private var priceText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Description", text: $item.description)
                .font(.body)
                .accessibilityLabel("Line item description")

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Qty")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("1", text: $qtyText)
                        .keyboardType(.decimalPad)
                        .frame(width: 50)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: qtyText) { _, val in
                            if let d = Decimal(string: val.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                                item.quantity = d
                            }
                        }
                        .accessibilityLabel("Quantity")
                }

                HStack(spacing: 4) {
                    Text("Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: priceText) { _, val in
                            if let d = Decimal(string: val.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                                item.unitPrice = d
                            }
                        }
                        .accessibilityLabel("Unit price")
                }

                Spacer()

                Text(formatCurrency(item.subtotal, code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            let fmt = NumberFormatter()
            fmt.numberStyle = .decimal
            fmt.maximumFractionDigits = 2
            fmt.minimumFractionDigits = 0
            qtyText = fmt.string(from: item.quantity as NSDecimalNumber) ?? "1"
            priceText = fmt.string(from: item.unitPrice as NSDecimalNumber) ?? "0"
        }
    }
}
