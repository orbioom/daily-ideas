import SwiftUI
import SwiftData

/// All transactions with filtering (by account / category) and swipe-to-delete.
struct TransactionsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Account.dateAdded) private var accounts: [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showAdd = false
    @State private var editTxn: Transaction?
    @State private var accountFilter: UUID?
    @State private var categoryFilter: UUID?
    @State private var searchText = ""

    private var filtered: [Transaction] {
        transactions.filter { txn in
            if let accountFilter, txn.accountRef?.id != accountFilter { return false }
            if let categoryFilter, txn.categoryRef?.id != categoryFilter { return false }
            if !searchText.isEmpty {
                let needle = searchText.lowercased()
                let hay = (txn.payee + " " + txn.note).lowercased()
                if !hay.contains(needle) { return false }
            }
            return true
        }
    }

    private var hasActiveFilter: Bool { accountFilter != nil || categoryFilter != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if transactions.isEmpty {
                    EmptyStateView(symbol: "list.bullet.rectangle",
                                   title: "No transactions",
                                   message: "Record what you earn and spend. Every entry keeps your budget honest.",
                                   actionTitle: accounts.isEmpty ? nil : "Add transaction",
                                   action: accounts.isEmpty ? nil : { showAdd = true })
                } else {
                    listContent
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add transaction")
                        .disabled(accounts.isEmpty)
                }
            }
            .searchable(text: $searchText, prompt: "Search payee or note")
            .sheet(isPresented: $showAdd) { TransactionEditor() }
            .sheet(item: $editTxn) { txn in TransactionEditor(existing: txn) }
        }
    }

    private var listContent: some View {
        List {
            if hasActiveFilter || !searchText.isEmpty {
                Section {
                    HStack {
                        Text("\(filtered.count) of \(transactions.count) shown")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                        Spacer()
                        if hasActiveFilter {
                            Button("Clear filters") {
                                accountFilter = nil
                                categoryFilter = nil
                            }
                            .font(Theme.rounded(13, .semibold))
                        }
                    }
                    .listRowBackground(Theme.surfaceAlt)
                }
            }

            if filtered.isEmpty {
                Section {
                    Text("No transactions match your filters.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .listRowBackground(Theme.surface)
                }
            } else {
                Section {
                    ForEach(filtered) { txn in
                        Button { editTxn = txn } label: {
                            TransactionRow(txn: txn, settings: settings)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(txn) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var filterMenu: some View {
        Menu {
            Picker("Account", selection: $accountFilter) {
                Text("All accounts").tag(UUID?.none)
                ForEach(accounts) { a in Text(a.name).tag(UUID?.some(a.id)) }
            }
            Picker("Category", selection: $categoryFilter) {
                Text("All categories").tag(UUID?.none)
                ForEach(categories) { c in Text("\(c.emoji) \(c.name)").tag(UUID?.some(c.id)) }
            }
        } label: {
            Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter transactions")
    }

    private func delete(_ txn: Transaction) {
        context.delete(txn)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
