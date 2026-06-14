import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Bindable var trip: Trip

    @State private var summary: BudgetEngine.Summary?
    @State private var isLoading = true
    @State private var editingExpense: Expense?
    @State private var showingAdd = false
    @State private var paywallReason: PaywallReason?

    private var sym: String { settings.currencySymbol }

    private var sortedExpenses: [Expense] {
        trip.expenses.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    loadingCard
                } else if let summary {
                    spendVsBudget(summary)
                    if isPro {
                        breakdownCard(summary)
                    } else {
                        proTeaser
                    }
                    expensesSection
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add expense")
            }
        }
        .sheet(isPresented: $showingAdd, onDismiss: recompute) {
            ExpenseEditor(trip: trip, expense: nil)
        }
        .sheet(item: $editingExpense, onDismiss: recompute) { expense in
            ExpenseEditor(trip: trip, expense: expense)
        }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .task(id: trip.id) { await computeSummary() }
    }

    // MARK: Loading

    private var loadingCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Crunching numbers…")
                LoadingRow()
                LoadingRow().frame(width: 200)
                LoadingRow().frame(width: 140)
            }
        }
        .accessibilityLabel("Computing budget")
    }

    // MARK: Spend vs budget

    private func spendVsBudget(_ s: BudgetEngine.Summary) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Spent vs budget")
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(BudgetEngine.currencyString(s.logged, symbol: sym))
                        .font(Theme.font(.largeTitle, weight: .bold))
                        .foregroundStyle(s.isOverBudget ? Theme.danger : Theme.textPrimary)
                    if s.hasBudget {
                        Text("/ \(BudgetEngine.currencyString(s.budget, symbol: sym))")
                            .font(Theme.font(.headline))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                if s.hasBudget {
                    Chart {
                        BarMark(x: .value("Spent", min(s.logged, s.budget)),
                                y: .value("Budget", "b"), stacking: .standard)
                            .foregroundStyle(s.isOverBudget ? Theme.danger : Theme.accent)
                        if s.logged < s.budget {
                            BarMark(x: .value("Remaining", s.budget - s.logged),
                                    y: .value("Budget", "b"), stacking: .standard)
                                .foregroundStyle(Theme.surfaceAlt)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 22)
                    .clipShape(Capsule())
                    .accessibilityLabel("Budget meter")
                    .accessibilityValue(s.spentFraction.map { "\(Int(($0 * 100).rounded())) percent of budget used" } ?? "No budget")

                    HStack {
                        Label(s.isOverBudget ? "Over by \(BudgetEngine.currencyString(s.logged - s.budget, symbol: sym))"
                                             : "\(BudgetEngine.currencyString(s.remaining, symbol: sym)) remaining",
                              systemImage: s.isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(Theme.font(.caption, weight: .semibold))
                            .foregroundStyle(s.isOverBudget ? Theme.danger : Theme.success)
                        Spacer()
                        Text("Planned \(BudgetEngine.currencyString(s.planned, symbol: sym))")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    Text("No budget set for this trip. Edit the trip to add one and track how you're doing.")
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Planned costs total \(BudgetEngine.currencyString(s.planned, symbol: sym)).")
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: Category breakdown (Pro)

    private func breakdownCard(_ s: BudgetEngine.Summary) -> some View {
        let slices = s.plannedByCategory.isEmpty ? s.loggedByCategory : s.plannedByCategory
        let title = s.plannedByCategory.isEmpty ? "Spending by category" : "Planned by category"
        let total = slices.reduce(0) { $0 + $1.amount }
        return CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title)
                if slices.isEmpty {
                    Text("Add itinerary costs or expenses to see a breakdown.")
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Amount", slice.amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(slice.category.tint)
                    }
                    .frame(height: 190)
                    .accessibilityLabel("Cost breakdown donut chart")
                    .accessibilityChartDescriptor(SliceDescriptor(slices: slices, symbol: sym))

                    VStack(spacing: 6) {
                        ForEach(slices) { slice in
                            HStack(spacing: 8) {
                                Circle().fill(slice.category.tint).frame(width: 10, height: 10)
                                Label(slice.category.label, systemImage: slice.category.symbol)
                                    .labelStyle(.titleOnly)
                                    .font(Theme.font(.caption, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(BudgetEngine.currencyString(slice.amount, symbol: sym))
                                    .font(Theme.font(.caption, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                if total > 0 {
                                    Text("\(Int((slice.amount / total * 100).rounded()))%")
                                        .font(Theme.font(.caption2))
                                        .foregroundStyle(Theme.textSecondary)
                                        .frame(width: 38, alignment: .trailing)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }

    private var proTeaser: some View {
        Button {
            Haptics.warning()
            paywallReason = .budget
        } label: {
            CardContainer {
                HStack(spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock budget analytics")
                            .font(Theme.font(.headline))
                            .foregroundStyle(Theme.textPrimary)
                        Text("See a category breakdown with Jaunt Pro.")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "lock.fill").foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Jaunt Pro")
    }

    // MARK: Expenses

    private var expensesSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Expenses", trailing: trip.expenses.isEmpty ? nil : "\(trip.expenses.count)")
                if trip.expenses.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard")
                            .font(.title)
                            .foregroundStyle(Theme.textSecondary)
                            .accessibilityHidden(true)
                        Text("No expenses logged yet")
                            .font(Theme.font(.subheadline))
                            .foregroundStyle(Theme.textSecondary)
                        Button("Log an expense") { showingAdd = true }
                            .font(Theme.font(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    ForEach(sortedExpenses) { expense in
                        expenseRow(expense)
                        if expense.id != sortedExpenses.last?.id {
                            Divider().overlay(Theme.separator)
                        }
                    }
                }
            }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        Button {
            Haptics.tap()
            editingExpense = expense
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(expense.category.tint.opacity(0.18)).frame(width: 34, height: 34)
                    Image(systemName: expense.category.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(expense.category.tint)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(expense.title)
                        .font(Theme.font(.body, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.font(.caption2))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(BudgetEngine.currencyString(expense.amount, symbol: sym))
                    .font(Theme.font(.body, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(expense.title), \(expense.category.label), \(BudgetEngine.currencyString(expense.amount, symbol: sym))")
        .accessibilityHint("Double tap to edit")
    }

    // MARK: Compute (async @MainActor)

    @MainActor
    private func computeSummary() async {
        isLoading = true
        // Yield so the loading state can render; keeps heavy reductions off the
        // first frame for large trips.
        try? await Task.sleep(nanoseconds: 250_000_000)
        summary = BudgetEngine.summary(for: trip)
        withAnimation(.easeOut(duration: 0.2)) { isLoading = false }
    }

    private func recompute() {
        Task { await computeSummary() }
    }
}

// MARK: - Audio chart descriptor

private struct SliceDescriptor: AXChartDescriptorRepresentable {
    let slices: [BudgetEngine.CategorySlice]
    let symbol: String

    func makeChartDescriptor() -> AXChartDescriptor {
        let categoryAxis = AXCategoricalDataAxisDescriptor(
            title: "Category",
            categoryOrder: slices.map { $0.category.label }
        )
        let maxAmount = slices.map { $0.amount }.max() ?? 1
        let valueAxis = AXNumericDataAxisDescriptor(
            title: "Amount",
            range: 0...max(maxAmount, 1),
            gridlinePositions: []
        ) { "\(BudgetEngine.currencyString($0, symbol: symbol))" }

        let series = AXDataSeriesDescriptor(
            name: "Cost by category",
            isContinuous: false,
            dataPoints: slices.map {
                AXDataPoint(x: $0.category.label, y: $0.amount)
            }
        )

        return AXChartDescriptor(
            title: "Cost by category",
            summary: nil,
            xAxis: categoryAxis,
            yAxis: valueAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
