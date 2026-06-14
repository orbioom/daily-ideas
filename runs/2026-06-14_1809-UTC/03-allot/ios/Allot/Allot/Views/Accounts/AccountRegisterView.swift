import SwiftUI
import SwiftData

/// Register for one account: its derived balance and its transactions.
struct AccountRegisterView: View {
    let account: Account

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query private var allTransactions: [Transaction]

    @State private var showAddTxn = false
    @State private var editTxn: Transaction?

    private var txns: [Transaction] {
        allTransactions
            .filter { $0.accountRef?.id == account.id }
            .sorted { $0.date > $1.date }
    }

    private var balance: Double {
        BudgetEngine.accountBalance(account, txns: allTransactions)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if txns.isEmpty {
                    EmptyStateView(symbol: "tray",
                                   title: "No transactions",
                                   message: "Add a transaction to this account to get started.",
                                   actionTitle: "Add transaction") { showAddTxn = true }
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(txns) { txn in
                            Button { editTxn = txn } label: {
                                TransactionRow(txn: txn, settings: settings, showAccount: false)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.surface)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddTxn = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add transaction")
            }
        }
        .sheet(isPresented: $showAddTxn) {
            TransactionEditor(preselectedAccount: account)
        }
        .sheet(item: $editTxn) { txn in
            TransactionEditor(existing: txn)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Balance")
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
            Text(settings.moneyMasked(balance))
                .font(Theme.money(34, .bold))
                .monospacedDigit()
                .foregroundStyle(balance < -0.005 ? Theme.bad : Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("\(account.type.label)\(account.onBudget ? "" : " · Off-budget")")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(account.name) balance")
        .accessibilityValue(settings.money(balance))
    }

    private func delete(at offsets: IndexSet) {
        let items = txns
        for index in offsets where items.indices.contains(index) {
            context.delete(items[index])
        }
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
