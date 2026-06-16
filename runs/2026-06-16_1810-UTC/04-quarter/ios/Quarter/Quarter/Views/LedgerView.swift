import SwiftUI
import SwiftData
import Charts

/// Income & expense CRUD with totals, category grouping, and Swift Charts analytics.
struct LedgerView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \IncomeEntry.date, order: .reverse) private var incomes: [IncomeEntry]
    @Query(sort: \ExpenseEntry.date, order: .reverse) private var expenses: [ExpenseEntry]

    @State private var mode: Mode = .expenses
    @State private var showAddIncome = false
    @State private var showAddExpense = false
    @State private var editingExpense: ExpenseEntry?
    @State private var editingIncome: IncomeEntry?

    enum Mode: String, CaseIterable, Identifiable {
        case expenses = "Expenses"
        case income = "Income"
        var id: String { rawValue }
    }

    private var incomeTotal: Double { incomes.reduce(0) { $0 + $1.amount } }
    private var expenseTotal: Double { expenses.reduce(0) { $0 + $1.amount } }
    private var netTotal: Double { incomeTotal - expenseTotal }

    var body: some View {
        NavigationStack {
            Group {
                if incomes.isEmpty && expenses.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .background(Theme.background)
            .navigationTitle("Ledger")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddIncome = true
                        } label: { Label("Add income", systemImage: "plus.circle") }
                        Button {
                            showAddExpense = true
                        } label: { Label("Add expense", systemImage: "minus.circle") }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add entry")
                }
            }
            .sheet(isPresented: $showAddIncome) { IncomeEditor() }
            .sheet(isPresented: $showAddExpense) { ExpenseEditor() }
            .sheet(item: $editingIncome) { IncomeEditor(entry: $0) }
            .sheet(item: $editingExpense) { ExpenseEditor(entry: $0) }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "list.bullet.rectangle.portrait",
            title: "Your ledger is empty",
            message: "Track income and business expenses here. Totals feed straight into your tax estimate.",
            actionTitle: "Add your first entry",
            action: { showAddExpense = true }
        )
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                summaryCard
                chartCard
                Picker("View", selection: $mode) {
                    ForEach(Mode.allCases) { m in Text(m.rawValue).tag(m) }
                }
                .pickerStyle(.segmented)

                if mode == .expenses {
                    expenseList
                } else {
                    incomeList
                }
            }
            .padding(Theme.Spacing.m)
        }
        .onChange(of: mode) { _, _ in Haptics.selection() }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: Theme.Spacing.m) {
            summaryStat(title: "Income", value: incomeTotal, color: Theme.accent)
            summaryStat(title: "Expenses", value: expenseTotal, color: Theme.warning)
            summaryStat(title: "Net", value: netTotal,
                        color: netTotal >= 0 ? Theme.accent : Theme.critical)
        }
        .card()
    }

    private func summaryStat(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            Text(Format.money(value))
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Format.money(value))
    }

    // MARK: - Charts

    @ViewBuilder
    private var chartCard: some View {
        if mode == .expenses && !expenses.isEmpty {
            expenseChart
        } else if mode == .income && (incomeTotal > 0 || expenseTotal > 0) {
            incomeVsExpenseChart
        }
    }

    private var expenseByCategory: [(category: String, total: Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped
            .map { (category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    private var expenseChart: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "Expenses by category", systemImage: "chart.pie")
            Chart(Array(expenseByCategory.enumerated()), id: \.offset) { index, item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.58),
                    angularInset: 1.5
                )
                .foregroundStyle(Theme.chartColor(for: index))
                .cornerRadius(4)
            }
            .frame(height: 200)
            .accessibilityLabel("Donut chart of expenses by category")
            .accessibilityValue(expenseByCategory.map { "\($0.category) \(Format.money($0.total))" }.joined(separator: ", "))

            // Legend
            VStack(spacing: Theme.Spacing.s) {
                ForEach(Array(expenseByCategory.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: Theme.Spacing.s) {
                        Circle()
                            .fill(Theme.chartColor(for: index))
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                        Text(item.category)
                            .font(.subheadline)
                        Spacer()
                        Text(Format.money(item.total))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(item.category)
                    .accessibilityValue(Format.money(item.total))
                }
            }
        }
        .card()
    }

    private var incomeVsExpenseChart: some View {
        let data: [(label: String, value: Double, color: Color)] = [
            ("Income", incomeTotal, Theme.accent),
            ("Expenses", expenseTotal, Theme.warning)
        ]
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "Income vs expenses", systemImage: "chart.bar")
            Chart(data, id: \.label) { item in
                BarMark(
                    x: .value("Type", item.label),
                    y: .value("Amount", item.value)
                )
                .foregroundStyle(item.color)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text(Format.money(item.value))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Bar chart, income versus expenses")
            .accessibilityValue("Income \(Format.money(incomeTotal)), expenses \(Format.money(expenseTotal))")
        }
        .card()
    }

    // MARK: - Lists

    private var expenseList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: "All expenses (\(expenses.count))")
            if expenses.isEmpty {
                Text("No expenses yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Theme.Spacing.m)
            } else {
                ForEach(expenses) { expense in
                    Button {
                        editingExpense = expense
                    } label: {
                        entryRow(
                            icon: ExpenseCategory.from(expense.category).systemImage,
                            title: expense.label.isEmpty ? expense.category : expense.label,
                            subtitle: "\(expense.category) · \(Format.shortDate(expense.date))",
                            amount: expense.amount,
                            color: Theme.warning,
                            negative: true
                        )
                    }
                    .buttonStyle(.plain)
                    .card()
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(expense)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private var incomeList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: "All income (\(incomes.count))")
            if incomes.isEmpty {
                Text("No income yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Theme.Spacing.m)
            } else {
                ForEach(incomes) { income in
                    Button {
                        editingIncome = income
                    } label: {
                        entryRow(
                            icon: income.isBusiness ? "briefcase" : "tray",
                            title: income.label.isEmpty ? income.source : income.label,
                            subtitle: "\(income.source) · \(Format.shortDate(income.date))",
                            amount: income.amount,
                            color: Theme.accent,
                            negative: false
                        )
                    }
                    .buttonStyle(.plain)
                    .card()
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(income)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private func entryRow(icon: String, title: String, subtitle: String,
                          amount: Double, color: Color, negative: Bool) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(Theme.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Text((negative ? "−" : "") + Format.money(amount))
                .monospacedDigit()
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityValue((negative ? "minus " : "") + Format.money(amount))
        .accessibilityHint("Double tap to edit")
    }

    // MARK: - Mutations

    private func delete(_ expense: ExpenseEntry) {
        context.delete(expense)
        try? context.save()
        Haptics.tap()
    }

    private func delete(_ income: IncomeEntry) {
        context.delete(income)
        try? context.save()
        Haptics.tap()
    }
}
