import SwiftUI
import SwiftData
import Charts

struct OverviewView: View {
    @Query(sort: \Account.sortIndex) private var accounts: [Account]
    @Query private var entries: [BalanceEntry]
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("hideBalances") private var hideBalances = false

    private var totals: (assets: Double, liabilities: Double, net: Double) { NetWorthEngine.totals(accounts) }
    private var series: [NetWorthPoint] {
        NetWorthEngine.monthlySeries(accounts: accounts, entries: entries, months: 12)
    }
    private var monthlyDelta: (Double, Double?) {
        guard series.count >= 2 else { return (0, nil) }
        let prev = series[series.count - 2].net
        let cur = series[series.count - 1].net
        let pct = prev != 0 ? (cur - prev) / abs(prev) * 100 : nil
        return (cur - prev, pct)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if accounts.isEmpty {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "Find out what you’re worth",
                                   message: "Add your accounts on the Accounts tab — assets and debts — and your net worth appears here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            netWorthCard
                            assetsLiabilitiesRow
                            if series.count >= 2 { trendCard }
                            insightCard
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Net worth")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { hideBalances.toggle(); Haptics.tap() } label: {
                        Image(systemName: hideBalances ? "eye.slash" : "eye")
                    }
                    .accessibilityLabel(hideBalances ? "Show balances" : "Hide balances")
                }
            }
        }
    }

    private func money(_ v: Double) -> String { hideBalances ? "••••" : Money.format(v, code: currencyCode, fraction: false) }

    private var netWorthCard: some View {
        Card(padding: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Total net worth").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                Text(money(totals.net))
                    .font(Theme.rounded(40, .bold))
                    .foregroundStyle(totals.net >= 0 ? Theme.ink : Theme.bad)
                    .minimumScaleFactor(0.5).lineLimit(1)
                if series.count >= 2 && !hideBalances {
                    HStack(spacing: 8) {
                        DeltaBadge(amount: monthlyDelta.0, percent: monthlyDelta.1, currency: currencyCode)
                        Text("this month").font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        }
    }

    private var assetsLiabilitiesRow: some View {
        HStack(spacing: 12) {
            valueCard("Assets", totals.assets, Theme.good, "arrow.up.circle.fill")
            valueCard("Liabilities", totals.liabilities, Theme.bad, "arrow.down.circle.fill")
        }
    }

    private func valueCard(_ title: String, _ value: Double, _ color: Color, _ icon: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon).foregroundStyle(color).font(.system(size: 15))
                    Text(title).font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                }
                Text(money(value)).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.5).lineLimit(1)
            }
        }
    }

    private var trendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Last 12 months").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(series) { pt in
                    AreaMark(x: .value("Month", pt.date), y: .value("Net worth", pt.net))
                        .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.35), Theme.accent.opacity(0.04)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Month", pt.date), y: .value("Net worth", pt.net))
                        .foregroundStyle(Theme.accent).interpolationMethod(.monotone)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) { Text(Money.compact(v, code: currencyCode)) }
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityLabel("Net worth trend over the last 12 months")
            }
        }
    }

    private var insightCard: some View {
        let avg = NetWorthEngine.averageMonthlyChange(series)
        return Card {
            HStack(spacing: 14) {
                Image(systemName: "sparkles").font(.system(size: 22)).foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    if let avg, avg != 0 {
                        Text(avg > 0 ? "Growing steadily" : "Trending down")
                            .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                        Text("About \(Money.compact(abs(avg), code: currencyCode)) a month \(avg > 0 ? "added" : "lost") lately.")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                    } else {
                        Text("Keep updating your balances")
                            .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                        Text("Log balances over a few months to see your growth rate.")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }
        }
    }
}
