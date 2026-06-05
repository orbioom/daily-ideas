import SwiftUI
import SwiftData

/// The group hub: a balances summary, an expenses list (swipe to edit/delete), and
/// the focal "Add expense" action. Links out to Members and Settle Up.
struct GroupDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var group: SplitGroup

    enum Tab: String, CaseIterable, Identifiable {
        case expenses, balances
        var id: String { rawValue }
        var title: String { self == .expenses ? "Expenses" : "Balances" }
    }

    @State private var tab: Tab = .expenses
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?
    @State private var showingEditGroup = false
    @State private var expenseToDelete: Expense?
    @State private var toast: String?

    var body: some View {
        ZStack {
            Brand.pageBackground

            VStack(spacing: 0) {
                Picker("View", selection: $tab) {
                    ForEach(Tab.allCases) { t in Text(t.title).tag(t) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Group {
                    switch tab {
                    case .expenses: expensesContent
                    case .balances: balancesContent
                    }
                }
            }

            VStack {
                Spacer()
                if !group.members.isEmpty {
                    InkButton(title: "Add expense", systemImage: "plus") {
                        showingAddExpense = true
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink {
                        MembersView(group: group)
                    } label: {
                        Label("Members", systemImage: "person.2")
                    }
                    NavigationLink {
                        SettleUpView(group: group)
                    } label: {
                        Label("Settle up", systemImage: "arrow.left.arrow.right")
                    }
                    Button {
                        showingEditGroup = true
                    } label: {
                        Label("Edit group", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Group options")
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            ExpenseEditView(group: group, expense: nil)
        }
        .sheet(item: $editingExpense) { expense in
            ExpenseEditView(group: group, expense: expense)
        }
        .sheet(isPresented: $showingEditGroup) {
            GroupEditView(group: group)
        }
        .alert("Delete this expense?", isPresented: deleteAlertBinding, presenting: expenseToDelete) { expense in
            Button("Delete", role: .destructive) { delete(expense) }
            Button("Cancel", role: .cancel) { expenseToDelete = nil }
        } message: { expense in
            Text("\"\(expense.title)\" will be permanently removed from this group.")
        }
        .overlay(alignment: .bottom) {
            if let toast { ToastView(message: toast) }
        }
    }

    // MARK: - Expenses

    @ViewBuilder
    private var expensesContent: some View {
        if group.members.isEmpty {
            EmptyStateView(
                icon: "person.crop.circle.badge.plus",
                title: "Add members first",
                message: "A group needs people before you can split anything. Add members from the menu.",
                actionTitle: "Manage members",
                action: nil
            )
            .frame(maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                NavigationLink {
                    MembersView(group: group)
                } label: {
                    Text("Manage members").fontWeight(.semibold)
                }
                .tint(Brand.text)
                .padding(.bottom, 40)
            }
        } else if group.expenses.isEmpty {
            EmptyStateView(
                icon: "tray",
                title: "No expenses yet",
                message: "Add the first shared cost and Split will keep the balances in step.",
                actionTitle: "Add expense",
                action: { showingAddExpense = true }
            )
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(group.orderedExpenses) { expense in
                    Button {
                        editingExpense = expense
                    } label: {
                        ExpenseRow(expense: expense, symbol: group.currencySymbol)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            expenseToDelete = expense
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingExpense = expense
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Brand.text2)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 64) }
        }
    }

    // MARK: - Balances

    @ViewBuilder
    private var balancesContent: some View {
        let analysis = GroupAnalysis(group: group)
        ScrollView {
            VStack(spacing: 16) {
                // Per-member net balances.
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Net balances")
                        ForEach(analysis.balances) { mb in
                            HStack(spacing: 12) {
                                MemberAvatar(member: mb.member, size: 30)
                                Text(mb.member.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                BalancePill(amount: mb.net, symbol: group.currencySymbol)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(mb.member.name), \(balanceWords(mb.net, symbol: group.currencySymbol))")
                        }
                    }
                }

                // Simplified settlement summary.
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Suggested settlement")
                        if analysis.isSettled {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Brand.live)
                                Text("Everyone is settled up.")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                            }
                        } else {
                            ForEach(analysis.transfers) { t in
                                TransferRow(transfer: t, symbol: group.currencySymbol)
                            }
                            NavigationLink {
                                SettleUpView(group: group)
                            } label: {
                                Text("Record a payment")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .tint(Brand.text)
                            .padding(.top, 2)
                        }
                    }
                }

                statsCard(analysis)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 90)
        }
    }

    private func statsCard(_ analysis: GroupAnalysis) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Group stats")
                statRow("Total spent",
                        Money.string(analysis.stats.totalSpent, symbol: group.currencySymbol))
                statRow("Expenses", "\(analysis.stats.expenseCount)")
                if let biggest = analysis.stats.biggestExpense {
                    statRow("Biggest",
                            "\(biggest.title) · \(Money.string(biggest.amount, symbol: group.currencySymbol))")
                }
                statRow("Recorded payments", "\(group.settlements.count)")
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(Brand.mono(14, weight: .medium))
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Helpers

    private var deleteAlertBinding: Binding<Bool> {
        Binding(get: { expenseToDelete != nil },
                set: { if !$0 { expenseToDelete = nil } })
    }

    private func delete(_ expense: Expense) {
        context.delete(expense)
        expenseToDelete = nil
        Haptics.warning(enabled: settings.hapticsEnabled)
        flash("Expense deleted")
    }

    private func balanceWords(_ amount: Decimal, symbol: String) -> String {
        if amount > 0 { return "is owed \(Money.string(amount, symbol: symbol))" }
        if amount < 0 { return "owes \(Money.string(abs(amount), symbol: symbol))" }
        return "is settled"
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease()) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(Brand.ease()) { toast = nil }
        }
    }
}

// MARK: - Rows

private struct ExpenseRow: View {
    var expense: Expense
    var symbol: String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 3) {
                Text(Money.string(expense.amount, symbol: symbol))
                    .font(Brand.mono(16, weight: .semibold))
                    .foregroundStyle(Brand.text)
                    .monospacedDigit()
                Text(expense.splitMode.shortTitle)
                    .font(.caption2)
                    .foregroundStyle(Brand.text3)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens to edit")
    }

    private var subtitle: String {
        let payer = expense.payer?.name ?? "Unknown"
        return "\(payer) paid · \(expense.date.formatted(date: .abbreviated, time: .omitted))"
    }

    private var accessibilityLabel: String {
        "\(expense.title), \(Money.string(expense.amount, symbol: symbol)), paid by \(expense.payer?.name ?? "unknown"), split \(expense.splitMode.shortTitle.lowercased())"
    }
}

struct TransferRow: View {
    var transfer: GroupAnalysis.NamedTransfer
    var symbol: String

    var body: some View {
        HStack(spacing: 10) {
            MemberAvatar(member: transfer.from, size: 26)
            Text(transfer.from.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
                .lineLimit(1)
            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
            MemberAvatar(member: transfer.to, size: 26)
            Text(transfer.to.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(Money.string(transfer.amount, symbol: symbol))
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.text)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transfer.from.name) pays \(transfer.to.name) \(Money.string(transfer.amount, symbol: symbol))")
    }
}
