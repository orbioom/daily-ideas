import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @Query(sort: \Account.sortIndex) private var accounts: [Account]
    @AppStorage("currencyCode") private var currencyCode = "USD"

    static let freeLimit = 6

    @State private var showAdd = false
    @State private var showPaywall = false

    private var assets: [Account] { accounts.filter { $0.isAsset } }
    private var liabilities: [Account] { accounts.filter { !$0.isAsset } }
    private var totals: (assets: Double, liabilities: Double, net: Double) { NetWorthEngine.totals(accounts) }

    private func attemptAdd() {
        if !pro.isPro && accounts.count >= Self.freeLimit { showPaywall = true } else { showAdd = true }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if accounts.isEmpty {
                    EmptyStateView(icon: "square.stack.3d.up.fill",
                                   title: "No accounts yet",
                                   message: "Add what you own and what you owe. Plumb keeps the running total — privately, on your device.",
                                   actionTitle: "Add account") { attemptAdd() }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if !assets.isEmpty { group("Assets", assets, Money.format(totals.assets, code: currencyCode)) }
                            if !liabilities.isEmpty { group("Liabilities", liabilities, "−" + Money.format(totals.liabilities, code: currencyCode)) }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { attemptAdd() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add account")
                }
            }
            .navigationDestination(for: Account.self) { AccountDetailView(account: $0) }
            .sheet(isPresented: $showAdd) {
                AccountEditView(account: nil, nextIndex: (accounts.map(\.sortIndex).max() ?? -1) + 1)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func group(_ title: String, _ list: [Account], _ total: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(total).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 4)
            Card(padding: 8) {
                VStack(spacing: 0) {
                    ForEach(list) { acc in
                        NavigationLink(value: acc) {
                            AccountRow(account: acc, currency: currencyCode).padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                        if acc.id != list.last?.id { Divider().background(Theme.hairline).padding(.leading, 64) }
                    }
                }
            }
        }
    }
}
