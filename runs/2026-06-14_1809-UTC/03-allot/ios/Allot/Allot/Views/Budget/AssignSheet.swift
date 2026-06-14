import SwiftUI
import SwiftData

/// Assign money to a category for the given month. Writes/updates an Allocation.
struct AssignSheet: View {
    let category: Category
    let monthKey: String

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var transactions: [Transaction]

    @State private var amountText: String = ""

    private var parsedAmount: Double? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value >= 0, value.isFinite else { return nil }
        return BudgetEngine.cents(value)
    }

    private var currentAssigned: Double { BudgetEngine.allocated(category, monthKey: monthKey) }
    private var spent: Double { BudgetEngine.spent(category, monthKey: monthKey, txns: transactions) }
    private var available: Double { BudgetEngine.available(category, upToMonth: monthKey, txns: transactions) }
    private var lastMonthAssigned: Double {
        BudgetEngine.allocated(category, monthKey: BudgetEngine.month(monthKey, offsetBy: -1))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(category.emoji).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                            Text(BudgetEngine.title(forMonthKey: monthKey))
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    statRow("Currently assigned", settings.money(currentAssigned), Theme.ink)
                    statRow("Spent this month", settings.money(spent), Theme.inkSoft)
                    statRow("Available", settings.money(available),
                            available < -0.005 ? Theme.bad : (available > 0.005 ? Theme.good : Theme.inkSoft))
                }

                Section("Assign amount") {
                    HStack {
                        Text(settings.currencySymbol)
                            .font(Theme.money(18, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(Theme.money(20, .semibold))
                            .monospacedDigit()
                    }
                }

                Section("Quick fill") {
                    quickButton("Set to last month (\(settings.money(lastMonthAssigned)))",
                                systemImage: "calendar.badge.clock",
                                enabled: lastMonthAssigned > 0.005) {
                        amountText = String(format: "%.2f", lastMonthAssigned)
                    }
                    quickButton("Cover overspending",
                                systemImage: "bandage.fill",
                                enabled: available < -0.005) {
                        let needed = currentAssigned + (-available)
                        amountText = String(format: "%.2f", max(needed, 0))
                    }
                    quickButton("Clear to zero", systemImage: "xmark.circle", enabled: currentAssigned > 0.005) {
                        amountText = "0.00"
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Assign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(parsedAmount == nil)
                }
            }
            .onAppear {
                if currentAssigned > 0.005 {
                    amountText = String(format: "%.2f", currentAssigned)
                }
            }
        }
    }

    private func statRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.money(15, .semibold)).monospacedDigit().foregroundStyle(color)
        }
    }

    private func quickButton(_ title: String, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(settings.hapticsEnabled)
            action()
        } label: {
            Label(title, systemImage: systemImage)
        }
        .disabled(!enabled)
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        // Find an existing allocation for this month, or create one.
        if let existing = category.allocations.first(where: { $0.monthKey == monthKey }) {
            existing.amount = amount
        } else {
            let alloc = Allocation(monthKey: monthKey, amount: amount, category: category)
            context.insert(alloc)
            category.allocations.append(alloc)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
