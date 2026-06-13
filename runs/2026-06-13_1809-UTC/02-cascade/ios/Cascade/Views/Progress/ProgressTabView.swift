import SwiftUI
import SwiftData
import Charts

struct ProgressTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Debt.sortIndex) private var debts: [Debt]
    @Query(sort: \PaymentLog.date, order: .reverse) private var logs: [PaymentLog]
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @State private var showLog = false

    private var totalPaid: Double { logs.reduce(0) { $0 + $1.amount } }
    private var clearedCount: Int { debts.filter { $0.balance <= 0.005 }.count }
    private var startingTotal: Double { debts.reduce(0) { $0 + $1.startingBalance } }
    private var currentTotal: Double { debts.reduce(0) { $0 + $1.balance } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if logs.isEmpty && debts.isEmpty {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "Track your wins",
                                   message: "Add debts, then log each payment here to watch your balance fall and celebrate every cleared debt.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statsRow
                            if !debts.isEmpty { paidDownCard }
                            if !logs.isEmpty { monthlyChart }
                            historySection
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showLog = true } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityLabel("Log a payment")
                        .disabled(debts.isEmpty)
                }
            }
            .sheet(isPresented: $showLog) { LogPaymentView() }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: Money.compact(totalPaid, code: currencyCode), label: "Paid so far", accent: Theme.good)
            StatTile(value: "\(clearedCount)", label: "Debts cleared", accent: Theme.accent)
            StatTile(value: "\(logs.count)", label: "Payments logged", accent: Theme.ink)
        }
    }

    private var paidDownCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Paid down").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let frac = startingTotal > 0 ? max(0, (startingTotal - currentTotal) / startingTotal) : 0
                ProgressBar(value: frac, height: 14)
                HStack {
                    Text(Money.format(max(0, startingTotal - currentTotal), code: currencyCode) + " of " + Money.format(startingTotal, code: currencyCode))
                        .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("\(Int(frac * 100))%").font(Theme.rounded(13, .bold)).foregroundStyle(Theme.good)
                }
            }
        }
    }

    private var monthlyChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Payments by month").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(monthlyTotals(), id: \.label) { item in
                    BarMark(x: .value("Month", item.label), y: .value("Paid", item.amount))
                        .foregroundStyle(Theme.accent)
                        .cornerRadius(4)
                }
                .frame(height: 160)
                .accessibilityLabel("Payments logged each month")
            }
        }
    }

    private var historySection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("History").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                if logs.isEmpty {
                    Text("No payments logged yet. Tap + to record one.")
                        .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        .padding(.vertical, 6)
                } else {
                    ForEach(logs.prefix(40)) { log in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.debtName).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                Text(Fmt.relativeDay(log.date)).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Text("−" + Money.format(log.amount, code: currencyCode))
                                .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.good)
                        }
                        .padding(.vertical, 6)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                context.delete(log); try? context.save()
                            }
                        }
                        if log.id != logs.prefix(40).last?.id { Divider().background(Theme.hairline) }
                    }
                }
            }
        }
    }

    private func monthlyTotals() -> [(label: String, amount: Double)] {
        let cal = Calendar.current
        var buckets: [Date: Double] = [:]
        for log in logs {
            let comps = cal.dateComponents([.year, .month], from: log.date)
            if let key = cal.date(from: comps) { buckets[key, default: 0] += log.amount }
        }
        return buckets.keys.sorted().suffix(8).map { key in
            (label: key.formatted(.dateTime.month(.abbreviated).year(.twoDigits)), amount: buckets[key] ?? 0)
        }
    }
}
