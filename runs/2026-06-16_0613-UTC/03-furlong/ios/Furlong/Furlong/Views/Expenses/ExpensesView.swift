import SwiftUI
import SwiftData

struct ExpensesView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var filter: ExpenseCategory? = nil
    @State private var editorExpense: Expense? = nil
    @State private var showEditor = false
    @State private var toast: String?
    @State private var deleteError: String?

    private var filtered: [Expense] {
        guard let filter else { return expenses }
        return expenses.filter { $0.category == filter }
    }

    private var grouped: [(key: Date, value: [Expense])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filtered) { e -> Date in
            let comps = cal.dateComponents([.year, .month], from: e.date)
            return cal.date(from: comps) ?? e.date
        }
        return groups.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if expenses.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorExpense = nil
                        showEditor = true
                        Haptics.impact(settings.hapticsEnabled)
                    } label: {
                        Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                    }
                    .accessibilityLabel("Log expense")
                }
                ToolbarItem(placement: .topBarLeading) { filterMenu }
            }
            .sheet(isPresented: $showEditor) {
                ExpenseEditorView(expense: editorExpense) {
                    toast = editorExpense == nil ? "Expense saved" : "Expense updated"
                }
            }
            .toast($toast)
            .alert("Couldn't delete expense", isPresented: .constant(deleteError != nil)) {
                Button("OK") { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                filter = nil
            } label: {
                if filter == nil { Label("All categories", systemImage: "checkmark") }
                else { Text("All categories") }
            }
            ForEach(ExpenseCategory.allCases) { c in
                Button {
                    filter = c
                    Haptics.selection(settings.hapticsEnabled)
                } label: {
                    if filter == c { Label(c.rawValue, systemImage: "checkmark") }
                    else { Label(c.rawValue, systemImage: c.symbol) }
                }
            }
        } label: {
            Image(systemName: filter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 16, weight: .semibold))
        }
        .accessibilityLabel("Filter by category")
    }

    private var list: some View {
        List {
            if filtered.isEmpty {
                Section {
                    Text("No \(filter?.rawValue.lowercased() ?? "") expenses match this filter.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .listRowBackground(Theme.surface)
                }
            }
            ForEach(grouped, id: \.key) { group in
                Section {
                    ForEach(group.value) { expense in
                        Button {
                            editorExpense = expense
                            showEditor = true
                        } label: {
                            ExpenseRow(expense: expense)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(expense) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(DateFormatting.monthYear.string(from: group.key))
                        Spacer()
                        Text(settings.money(group.value.reduce(Decimal(0)) { $0 + $1.amount }))
                            .font(Theme.mono(12, .semibold))
                    }
                    .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func delete(_ expense: Expense) {
        Haptics.impact(settings.hapticsEnabled, style: .medium)
        context.delete(expense)
        do {
            try context.save()
            toast = "Expense deleted"
        } catch {
            deleteError = "Please try again."
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "creditcard.fill",
            title: "No expenses yet",
            message: "Add fuel, tolls, maintenance and more. Deductible expenses roll into your year total.",
            actionTitle: "Log an expense") {
                editorExpense = nil
                showEditor = true
                Haptics.impact(settings.hapticsEnabled)
            }
    }
}
