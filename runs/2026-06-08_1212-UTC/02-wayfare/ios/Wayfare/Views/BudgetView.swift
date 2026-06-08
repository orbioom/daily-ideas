import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var context
    @State private var editingExpense: Expense?

    private let engine = TripEngine()

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    if !engine.spentByCategory(trip).isEmpty { breakdownCard }
                    expensesCard
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Haptics.tap()
                    editingExpense = newExpense()
                } label: { Label("Add expense", systemImage: "plus") }
                    .buttonStyle(InkButtonStyle())
                    .padding()
                    .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingExpense) { ExpenseEditorView(expense: $0, trip: trip) }
    }

    private var summaryCard: some View {
        let spent = engine.totalSpent(trip)
        let remaining = engine.budgetRemaining(trip)
        let fraction = engine.budgetFraction(trip)
        return VStack(spacing: 14) {
            if trip.budget > 0 {
                ZStack {
                    Circle().stroke(Brand.hairline, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: min(1, fraction))
                        .stroke(fraction > 1 ? Brand.danger : Color.accentColor,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text(Money.compact(spent, code: trip.currencyCode))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(Brand.text)
                        Text("of \(Money.compact(trip.budget, code: trip.currencyCode))")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                .frame(width: 160, height: 160)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Spent \(Money.string(spent, code: trip.currencyCode)) of \(Money.string(trip.budget, code: trip.currencyCode))")

                if let remaining {
                    Text(remaining >= 0
                         ? "\(Money.string(remaining, code: trip.currencyCode)) remaining"
                         : "\(Money.string(-remaining, code: trip.currencyCode)) over budget")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(remaining >= 0 ? Brand.live : Brand.danger)
                }
            } else {
                VStack(spacing: 6) {
                    Text(Money.string(spent, code: trip.currencyCode))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text("total spent · no budget set")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var breakdownCard: some View {
        let totals = engine.spentByCategory(trip)
        return VStack(alignment: .leading, spacing: 12) {
            Text("By category").font(.headline).foregroundStyle(Brand.text)
            Chart(totals) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(Color(hex: item.category.colorHex))
                .cornerRadius(3)
            }
            .frame(height: 160)
            ForEach(totals) { item in
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: item.category.colorHex)).frame(width: 9, height: 9)
                    Text(item.category.label).font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Text(Money.string(item.amount, code: trip.currencyCode))
                        .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text)
                }
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private var expensesCard: some View {
        if trip.expenses.isEmpty {
            EmptyStateView(
                icon: "creditcard",
                title: "No expenses logged",
                message: "Add what you spend to track it against your budget by category."
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Expenses").font(.headline).foregroundStyle(Brand.text)
                ForEach(trip.expenses.sorted { $0.date > $1.date }) { exp in
                    Button { editingExpense = exp } label: {
                        HStack(spacing: 12) {
                            Image(systemName: exp.category.symbol)
                                .foregroundStyle(Color(hex: exp.category.colorHex))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exp.title.isEmpty ? exp.category.label : exp.title)
                                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Text(Format.shortDate.string(from: exp.date))
                                    .font(.caption).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            Text(Money.string(exp.amount, code: trip.currencyCode))
                                .font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            context.delete(exp); Haptics.warning()
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .glassCard()
        }
    }

    private func newExpense() -> Expense {
        let exp = Expense(title: "", amount: 0, trip: trip)
        context.insert(exp)
        return exp
    }
}
