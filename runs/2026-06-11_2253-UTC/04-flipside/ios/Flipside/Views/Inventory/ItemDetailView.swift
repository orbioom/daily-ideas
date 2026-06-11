import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showListSheet = false
    @State private var showSaleSheet = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                if item.status == .sold, let sale = item.sale {
                    saleCard(sale)
                } else {
                    actionCard
                }
                economicsCard
                if !item.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(.headline)
                        Text(item.notes)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSoft(scheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .flipCard()
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete item", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
        }
        .background(Theme.background(scheme))
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) { ItemEditorView(item: item) }
        .sheet(isPresented: $showListSheet) { ListItemSheet(item: item) }
        .sheet(isPresented: $showSaleSheet) { RecordSaleSheet(item: item) }
        .confirmationDialog("Delete \(item.title)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(item)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusChip(status: item.status)
                Spacer()
                Text(item.source.label)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
            Text(item.title)
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink(scheme))
            Text("\(item.category.label) · sourced \(item.sourcedDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .flipCard()
    }

    private var actionCard: some View {
        VStack(spacing: 10) {
            if item.status == .sourced {
                Text("Sitting in the death pile since \(item.sourcedDate.formatted(date: .abbreviated, time: .omitted)).")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    showListSheet = true
                } label: {
                    Label("Mark as listed", systemImage: "tag.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.tangerine)
            } else if item.status == .listed {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Asking")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft(scheme))
                        Text(ProfitEngine.money(item.listPrice))
                            .font(Theme.display(24))
                            .foregroundStyle(Theme.tangerine)
                    }
                    Spacer()
                    if let listed = item.listedDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Listed")
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft(scheme))
                            Text(listed.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
                Button {
                    showSaleSheet = true
                } label: {
                    Label("Record sale", systemImage: "dollarsign.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.teal)
            }
        }
        .flipCard()
    }

    private func saleCard(_ sale: Sale) -> some View {
        let profit = ProfitEngine.profit(item: item) ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sold on \(sale.platform.label)")
                    .font(.headline)
                Spacer()
                Text(sale.soldDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
            ledgerRow("Sale price", sale.soldPrice, positive: true)
            ledgerRow("Platform fees", -sale.fees, positive: false)
            ledgerRow("Shipping", -sale.shipping, positive: false)
            ledgerRow("Cost of goods", -item.cost, positive: false)
            Divider()
            HStack {
                Text("Net profit")
                    .font(.headline)
                Spacer()
                Text(ProfitEngine.money(profit))
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.profitColor(profit))
            }
            if let roi = ProfitEngine.roi(item: item) {
                Text("\(Int((roi * 100).rounded()))% ROI · sold in \(ProfitEngine.daysToSell(item: item) ?? 0) days")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
        }
        .flipCard()
        .accessibilityElement(children: .combine)
    }

    private func ledgerRow(_ label: String, _ value: Double, positive: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft(scheme))
            Spacer()
            Text(ProfitEngine.money(value))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(positive ? Theme.teal : Theme.ink(scheme))
        }
    }

    private var economicsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick math").font(.headline)
            if item.status == .listed && item.listPrice > 0 {
                let estFees = item.listPrice * Platform.ebay.defaultFeeRate
                let estProfit = item.listPrice - estFees - item.cost
                Text("At \(ProfitEngine.money(item.listPrice)) on eBay (≈\(Int(Platform.ebay.defaultFeeRate * 100))% fees, before shipping) you'd net about \(ProfitEngine.money(estProfit)).")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else if item.status == .sourced {
                Text("Cost \(ProfitEngine.money(item.cost)). List it to start the clock — items that sit unlisted earn nothing.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                Text("This flip is closed. The numbers above are final.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .flipCard()
    }
}

/// Sheet: mark a sourced item as listed.
struct ListItemSheet: View {
    @Bindable var item: Item
    @Environment(\.dismiss) private var dismiss
    @State private var priceText = ""
    @State private var date = Date()
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("Asking price")
                    Spacer()
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)
                        .accessibilityLabel("Asking price")
                }
                DatePicker("Listed on", selection: $date, in: ...Date(), displayedComponents: .date)
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
            }
            .navigationTitle("Mark listed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("List it") {
                        let cleaned = priceText.replacingOccurrences(of: ",", with: ".")
                        guard let price = Double(cleaned), price > 0 else {
                            error = "Enter a price above zero."
                            return
                        }
                        item.listPrice = price
                        item.listedDate = date
                        item.statusRaw = ItemStatus.listed.rawValue
                        Haptics.success()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// Sheet: record the sale of a listed item, with platform fee prefill.
struct RecordSaleSheet: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var platform: Platform = .ebay
    @State private var priceText = ""
    @State private var feesText = ""
    @State private var shippingText = ""
    @State private var date = Date()
    @State private var feesEdited = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Platform", selection: $platform) {
                    ForEach(Platform.allCases) { Text($0.label).tag($0) }
                }
                HStack {
                    Text("Sold for")
                    Spacer()
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)
                        .accessibilityLabel("Sold price")
                }
                HStack {
                    Text("Fees")
                    Spacer()
                    TextField("0.00", text: $feesText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)
                        .accessibilityLabel("Platform fees")
                        .onChange(of: feesText) { _, _ in
                            // Only treat as a manual edit when it differs from our prefill.
                            if feesText != prefillFees() { feesEdited = true }
                        }
                }
                HStack {
                    Text("Shipping you paid")
                    Spacer()
                    TextField("0.00", text: $shippingText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)
                        .accessibilityLabel("Shipping cost")
                }
                DatePicker("Sold on", selection: $date, in: ...Date(), displayedComponents: .date)
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
                Section {
                    Text("Fees prefill at \(platform.label)'s typical rate (\(String(format: "%.1f", platform.defaultFeeRate * 100))%) — adjust to the real number from your sale receipt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Record sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save sale") { save() }
                }
            }
            .onAppear {
                if item.listPrice > 0 {
                    priceText = String(format: "%.2f", item.listPrice)
                }
                feesText = prefillFees()
            }
            .onChange(of: platform) { _, _ in
                if !feesEdited { feesText = prefillFees() }
            }
            .onChange(of: priceText) { _, _ in
                if !feesEdited { feesText = prefillFees() }
            }
        }
        .presentationDetents([.large])
    }

    private func prefillFees() -> String {
        let cleaned = priceText.replacingOccurrences(of: ",", with: ".")
        let price = Double(cleaned) ?? 0
        return String(format: "%.2f", price * platform.defaultFeeRate)
    }

    private func parse(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        if cleaned.isEmpty { return 0 }
        guard let v = Double(cleaned), v >= 0, v < 1_000_000 else { return nil }
        return v
    }

    private func save() {
        guard let price = parse(priceText), price > 0 else {
            error = "Enter the sale price."
            return
        }
        guard let fees = parse(feesText), let shipping = parse(shippingText) else {
            error = "Fees and shipping must be valid amounts."
            return
        }
        let sale = Sale(soldPrice: price, fees: fees, shipping: shipping,
                        soldDate: date, platform: platform)
        sale.item = item
        context.insert(sale)
        item.statusRaw = ItemStatus.sold.rawValue
        Haptics.success()
        dismiss()
    }
}
