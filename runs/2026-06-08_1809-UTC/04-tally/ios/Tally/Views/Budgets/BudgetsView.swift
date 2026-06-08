import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var context
    @Query private var budgets: [BudgetItem]
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var editing: BudgetItem?
    @State private var showAdd = false

    private var monthTxns: [Transaction] { MoneyEngine.transactions(all, inMonth: .now) }
    private var statuses: [MoneyEngine.BudgetStatus] {
        MoneyEngine.budgetStatuses(budgets, monthTxns: monthTxns)
    }
    private var totalLimit: Double { MoneyEngine.totalBudget(budgets) }
    private var totalSpent: Double { MoneyEngine.summary(monthTxns).expense }

    private var unbudgeted: [Category] {
        let have = Set(budgets.map { $0.category })
        return Category.expenseCases.filter { !have.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if budgets.isEmpty {
                    EmptyStateView(icon: "chart.bar.fill",
                                   title: "No budgets yet",
                                   message: "Add a monthly limit for a category to keep an eye on it.")
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            overallCard
                            ForEach(statuses) { s in
                                Button { edit(s.category) } label: { BudgetRow(status: s, currency: currency) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .disabled(unbudgeted.isEmpty)
                        .accessibilityLabel("Add budget")
                }
            }
            .sheet(item: $editing) { b in BudgetEditorView(budget: b) }
            .sheet(isPresented: $showAdd) { BudgetEditorView(availableCategories: unbudgeted) }
        }
    }

    private var overallCard: some View {
        let frac = totalLimit > 0 ? min(totalSpent / totalLimit, 1) : 0
        let over = totalSpent > totalLimit && totalLimit > 0
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "This month")
                Spacer()
                Text("\(Money.format(totalSpent, code: currency)) / \(Money.format(totalLimit, code: currency))")
                    .font(Brand.mono(12)).foregroundStyle(over ? Brand.danger : Brand.text2)
            }
            ProgressBar(fraction: frac, tint: over ? Brand.danger : Color(hex: 0x3E9E78))
            Text(over ? "Over budget by \(Money.format(totalSpent - totalLimit, code: currency))"
                      : "\(Money.format(max(0, totalLimit - totalSpent), code: currency)) left across all budgets")
                .font(.caption).foregroundStyle(over ? Brand.danger : Brand.text3)
        }
        .glassCard()
    }

    private func edit(_ category: Category) {
        editing = budgets.first { $0.category == category }
    }
}

struct ProgressBar: View {
    let fraction: Double
    var tint: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline).frame(height: 10)
                Capsule().fill(tint)
                    .frame(width: max(6, geo.size.width * min(max(fraction, 0), 1)), height: 10)
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

struct BudgetRow: View {
    let status: MoneyEngine.BudgetStatus
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: status.category.icon).foregroundStyle(status.category.color).frame(width: 24)
                Text(status.category.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Spacer()
                Text("\(Money.format(status.spent, code: currency)) / \(Money.format(status.limit, code: currency))")
                    .font(Brand.mono(11)).foregroundStyle(status.isOver ? Brand.danger : Brand.text2)
            }
            ProgressBar(fraction: status.fraction, tint: status.isOver ? Brand.danger : status.category.color)
            Text(status.isOver ? "Over by \(Money.format(-status.remaining, code: currency))"
                               : "\(Money.format(status.remaining, code: currency)) left")
                .font(.caption2).foregroundStyle(status.isOver ? Brand.danger : Brand.text3)
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.category.title), \(Money.format(status.spent, code: currency)) of \(Money.format(status.limit, code: currency)) spent")
    }
}
