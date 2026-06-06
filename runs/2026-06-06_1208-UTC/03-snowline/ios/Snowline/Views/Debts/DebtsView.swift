import SwiftUI
import SwiftData

/// All debts with totals and quick access to detail/editing.
struct DebtsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Debt.order) private var debts: [Debt]
    @AppStorage("currencyCode") private var currency = "USD"

    @State private var newDebt: Debt?

    private var totalBalance: Double { debts.filter { $0.includeInPlan }.reduce(0) { $0 + $1.balance } }
    private var totalMin: Double { debts.filter { $0.includeInPlan }.reduce(0) { $0 + $1.minPayment } }
    private var weightedAPR: Double {
        let active = debts.filter { $0.includeInPlan && $0.balance > 0 }
        let total = active.reduce(0) { $0 + $1.balance }
        guard total > 0 else { return 0 }
        return active.reduce(0) { $0 + $1.apr * $1.balance } / total
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if debts.isEmpty {
                        EmptyStateView(icon: "list.bullet.rectangle.portrait",
                                       title: "No debts yet",
                                       message: "Add a card or loan to start building your payoff plan.")
                    } else { list }
                }
            }
            .navigationTitle("Debts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { create() } label: { Image(systemName: "plus") }.accessibilityLabel("Add debt")
                }
            }
            .navigationDestination(for: Debt.self) { DebtDetailView(debt: $0) }
            .sheet(item: $newDebt) { DebtEditView(debt: $0, isNew: true) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatTile(value: Money.compact(totalBalance, code: currency), label: "Total owed", tint: Brand.text)
                    StatTile(value: Money.compact(totalMin, code: currency), label: "Min / month")
                    StatTile(value: String(format: "%.1f%%", weightedAPR), label: "Avg APR", tint: Brand.warn)
                }
                ForEach(debts) { debt in
                    NavigationLink(value: debt) { DebtRow(debt: debt, currency: currency) }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { delete(debt) } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func create() {
        let d = Debt(name: "")
        d.order = (debts.map(\.order).max() ?? -1) + 1
        context.insert(d); newDebt = d; Haptics.tap()
    }
    private func delete(_ d: Debt) { context.delete(d); try? context.save(); Haptics.warning() }
}

private struct DebtRow: View {
    let debt: Debt
    let currency: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: debt.kind.symbol).font(.title3).foregroundStyle(Brand.text2)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(debt.name.isEmpty ? "Untitled debt" : debt.name)
                    .font(.headline).foregroundStyle(Brand.text)
                HStack(spacing: 8) {
                    Text(String(format: "%.2f%% APR", debt.apr)).font(.caption).foregroundStyle(Brand.text3)
                    if !debt.includeInPlan { Pill(text: "Excluded", tint: Brand.text3) }
                    if debt.balance > 0 && debt.minPayment <= debt.monthlyInterest && debt.apr > 0 {
                        Pill(text: "Min < interest", tint: Brand.danger)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.string(debt.balance, code: currency))
                    .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                Text("min \(Money.string(debt.minPayment, code: currency))")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
}
