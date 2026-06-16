import SwiftUI
import SwiftData

struct PropertyDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Bindable var property: Property

    @State private var showEdit = false
    @State private var showAddUnit = false
    @State private var editingUnit: Unit?
    @State private var showAddTxn = false
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var toastMessage: String?

    private var metrics: PropertyMetrics {
        FinanceEngine.metrics(for: property, settings: settings.closingCostPct)
    }

    private var sortedTransactions: [Txn] {
        property.transactions.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                header
                metricGrid
                unitsSection
                transactionsSection
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle(property.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit property", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete property", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Property options")
            }
        }
        .sheet(isPresented: $showEdit) {
            PropertyEditorView(property: property) { _ in
                toastMessage = "Property updated"
            }
        }
        .sheet(isPresented: $showAddUnit) {
            UnitEditorView(property: property, unit: nil) { toastMessage = "Unit added" }
        }
        .sheet(item: $editingUnit) { unit in
            UnitEditorView(property: property, unit: unit) { toastMessage = "Unit updated" }
        }
        .sheet(isPresented: $showAddTxn) {
            TransactionEditorView(property: property) { toastMessage = "Transaction added" }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .confirmationDialog("Delete this property?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete \(property.name)", role: .destructive) { deleteProperty() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the property and all its units, leases, and transactions. This cannot be undone.")
        }
        .toast($toastMessage)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                        .fill(property.identityGradient)
                        .frame(width: 64, height: 64)
                    Image(systemName: property.type.systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.type.rawValue)
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                    Text(property.address)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            if !property.notes.isEmpty {
                Text(property.notes)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardSurface()
    }

    private var metricGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        let cashFlowColor = metrics.monthlyCashFlow >= 0 ? Theme.good : Theme.bad

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Financials")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                if !pro.isPro {
                    Spacer()
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Advanced", systemImage: "lock.fill")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }

            LazyVGrid(columns: columns, spacing: 12) {
                MetricTile(
                    title: "Monthly cash flow",
                    value: Money.formatSigned(metrics.monthlyCashFlow, currencyCode: settings.currencyCode),
                    caption: "Income − exp − debt",
                    systemImage: "arrow.left.arrow.right",
                    valueColor: cashFlowColor
                )
                MetricTile(
                    title: "Equity",
                    value: Money.format(metrics.equity, currencyCode: settings.currencyCode),
                    caption: "Value − mortgage",
                    systemImage: "chart.pie.fill"
                )
                MetricTile(
                    title: "NOI (annual)",
                    value: Money.format(metrics.noi, currencyCode: settings.currencyCode),
                    caption: "Excludes debt & CapEx",
                    systemImage: "banknote.fill"
                )
                if pro.isPro {
                    MetricTile(
                        title: "Cap rate",
                        value: metrics.capRate.map { Percent.format($0) } ?? "—",
                        caption: "NOI / value",
                        systemImage: "percent"
                    )
                    MetricTile(
                        title: "Cash-on-cash",
                        value: metrics.cashOnCash.map { Percent.format($0) } ?? "—",
                        caption: "Return on cash in",
                        systemImage: "dollarsign.arrow.circlepath"
                    )
                    MetricTile(
                        title: "Gross rent mult.",
                        value: metrics.grossRentMultiplier.map { Money.round($0, scale: 1).description } ?? "—",
                        caption: "Price / annual rent",
                        systemImage: "x.squareroot"
                    )
                } else {
                    proLockedTile("Cap rate")
                    proLockedTile("Cash-on-cash")
                    proLockedTile("Gross rent mult.")
                }
            }
        }
    }

    private func proLockedTile(_ title: String) -> some View {
        Button {
            showPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Pro")
                        .font(Theme.rounded(18, .bold))
                }
                .foregroundStyle(Theme.accent)
                Text("Tap to unlock")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), Pro feature")
        .accessibilityHint("Opens the upgrade screen")
    }

    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Units")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    showAddUnit = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(Theme.rounded(14, .semibold))
                }
                .accessibilityLabel("Add unit")
            }

            if property.units.isEmpty {
                Text("No units yet. Add a unit to track tenants and rent.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardSurface()
            } else {
                ForEach(property.units.sorted { $0.label < $1.label }) { unit in
                    UnitRow(unit: unit)
                        .onTapGesture { editingUnit = unit }
                }
            }
        }
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transactions")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    showAddTxn = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(Theme.rounded(14, .semibold))
                }
                .accessibilityLabel("Add transaction")
            }

            if sortedTransactions.isEmpty {
                Text("No transactions yet. Log income and expenses to compute returns.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardSurface()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedTransactions.prefix(40))) { txn in
                        TransactionRow(txn: txn)
                            .padding(.vertical, 10)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(txn)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        if txn.id != sortedTransactions.prefix(40).last?.id {
                            Divider().overlay(Theme.hairline)
                        }
                    }
                }
                .cardSurface()
                if sortedTransactions.count > 40 {
                    Text("Showing 40 of \(sortedTransactions.count). Export from Reports for the full list.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private func delete(_ txn: Txn) {
        context.delete(txn)
        try? context.save()
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        toastMessage = "Transaction deleted"
    }

    private func deleteProperty() {
        context.delete(property)
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}

private struct TransactionRow: View {
    let txn: Txn
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: txn.category.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(txn.kind.color)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(txn.category.rawValue)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(txn.notes.isEmpty ? DateText.full(txn.date) : "\(DateText.short(txn.date)) · \(txn.notes)")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(Money.formatSigned(txn.signedAmount, currencyCode: settings.currencyCode))
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(txn.kind.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(txn.category.rawValue), \(DateText.full(txn.date))")
        .accessibilityValue(Money.formatSigned(txn.signedAmount, currencyCode: settings.currencyCode))
    }
}
