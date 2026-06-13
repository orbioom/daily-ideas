import SwiftUI
import SwiftData

struct DebtsView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @Query(sort: \Debt.sortIndex) private var debts: [Debt]

    static let freeLimit = 4

    @AppStorage("monthlyBudget") private var monthlyBudget = 0.0
    @AppStorage("strategyRaw") private var strategyRaw = PayoffStrategy.snowball.rawValue
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @State private var editing: Debt?
    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var toDelete: Debt?

    private func attemptAdd() {
        if !pro.isPro && debts.count >= Self.freeLimit { showPaywall = true }
        else { showAdd = true }
    }

    private var strategy: PayoffStrategy { PayoffStrategy(rawValue: strategyRaw) ?? .snowball }
    private var totalBalance: Double { debts.reduce(0) { $0 + $1.balance } }
    private var totalMin: Double { debts.reduce(0) { $0 + $1.minimumPayment } }
    private var startingTotal: Double { debts.reduce(0) { $0 + $1.startingBalance } }
    private var paidOff: Double { max(0, startingTotal - totalBalance) }
    private var effectiveBudget: Double { max(monthlyBudget, totalMin) }

    private var plan: PayoffPlan {
        PayoffEngine.simulate(debts.map(\.snapshot), monthlyBudget: effectiveBudget, strategy: strategy)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if debts.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle.fill",
                        title: "No debts yet",
                        message: "Add what you owe — cards, loans, anything with a balance — and Cascade will map your way out.",
                        actionTitle: "Add your first debt") { attemptAdd() }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryCard
                            ForEach(debts) { debt in
                                Button { editing = debt } label: {
                                    Card { DebtRow(debt: debt, currency: currencyCode) }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Edit") { editing = debt }
                                    Button("Delete", role: .destructive) { toDelete = debt }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("My debts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { attemptAdd() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add debt")
                }
            }
            .sheet(isPresented: $showAdd) {
                DebtEditView(debt: nil, nextIndex: (debts.map(\.sortIndex).max() ?? -1) + 1)
            }
            .sheet(item: $editing) { d in
                DebtEditView(debt: d, nextIndex: d.sortIndex)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Delete this debt?", isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } })) {
                Button("Delete", role: .destructive) {
                    if let d = toDelete { context.delete(d); try? context.save(); Haptics.warning() }
                    toDelete = nil
                }
                Button("Cancel", role: .cancel) { toDelete = nil }
            } message: {
                Text("This removes the debt from your plan. Logged payments are kept in Progress.")
            }
        }
    }

    private var summaryCard: some View {
        Card(padding: 20) {
            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total owed")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        Text(Money.format(totalBalance, code: currencyCode))
                            .font(Theme.rounded(34, .bold))
                            .foregroundStyle(Theme.ink)
                            .minimumScaleFactor(0.6).lineLimit(1)
                    }
                    Spacer()
                    RingView(progress: startingTotal > 0 ? paidOff / startingTotal : 0,
                             lineWidth: 10, size: 76, tint: Theme.accent,
                             center: AnyView(
                                Text("\(Int((startingTotal > 0 ? paidOff / startingTotal : 0) * 100))%")
                                    .font(Theme.rounded(16, .bold))
                                    .foregroundStyle(Theme.ink)))
                }
                Divider().background(Theme.hairline)
                HStack {
                    freeDateBlock
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Min. payments / mo")
                            .font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.inkSoft)
                        Text(Money.format(totalMin, code: currencyCode))
                            .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var freeDateBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Debt-free")
                .font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.inkSoft)
            if let months = plan.payoffMonths, let date = plan.payoffDate {
                Text(Fmt.monthYear(date))
                    .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.accent)
                Text(Fmt.monthsLabel(months) + " to go")
                    .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
            } else {
                Text("Out of reach")
                    .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.warn)
                Text("Raise your budget in Plan")
                    .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
            }
        }
    }
}
