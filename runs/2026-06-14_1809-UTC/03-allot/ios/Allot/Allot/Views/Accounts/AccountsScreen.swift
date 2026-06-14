import SwiftUI
import SwiftData

/// List of accounts with derived balances, a net total, and net worth.
struct AccountsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Account.dateAdded) private var accounts: [Account]
    @Query private var transactions: [Transaction]

    @State private var showAdd = false
    @State private var paywall: PaywallReason?

    private var netWorth: Double { BudgetEngine.netWorth(accounts, txns: transactions) }
    private var onBudgetTotal: Double { BudgetEngine.onBudgetTotal(accounts, txns: transactions) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if accounts.isEmpty {
                    EmptyStateView(symbol: "wallet.pass",
                                   title: "No accounts yet",
                                   message: "Add your checking, savings, cash, or credit card to start tracking real money.",
                                   actionTitle: "Add account") { addTapped() }
                } else {
                    content
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addTapped() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add account")
                }
            }
            .sheet(isPresented: $showAdd) { AddAccountSheet() }
            .sheet(item: $paywall) { r in PaywallView(reason: r) }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                summaryCard
                ForEach(accounts) { account in
                    NavigationLink {
                        AccountRegisterView(account: account)
                    } label: {
                        AccountRow(account: account,
                                   balance: BudgetEngine.accountBalance(account, txns: transactions),
                                   settings: settings)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private var summaryCard: some View {
        CardSection {
            HStack {
                summaryTile("Net worth", netWorth)
                Divider().frame(height: 40).overlay(Theme.hairline)
                summaryTile("On-budget", onBudgetTotal)
            }
        }
    }

    private func summaryTile(_ label: String, _ value: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
            Text(settings.moneyMasked(value))
                .font(Theme.money(22, .bold))
                .monospacedDigit()
                .foregroundStyle(value < -0.005 ? Theme.bad : Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(settings.money(value))
    }

    private func addTapped() {
        if Pro.canAddAccount(currentCount: accounts.count, isPro: isPro) {
            showAdd = true
        } else {
            paywall = .accountLimit
        }
    }
}

/// Single account row in the list.
private struct AccountRow: View {
    let account: Account
    let balance: Double
    let settings: AppSettings

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: account.type.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.accentSoft))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    Text(account.type.label)
                    if !account.onBudget {
                        Text("· Off-budget")
                    }
                }
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text(settings.moneyMasked(balance))
                .font(Theme.money(17, .bold))
                .monospacedDigit()
                .foregroundStyle(balance < -0.005 ? Theme.bad : Theme.ink)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(account.name), \(account.type.label)\(account.onBudget ? "" : ", off budget")")
        .accessibilityValue("Balance \(settings.money(balance))")
        .accessibilityHint("Double tap to open register")
    }
}
