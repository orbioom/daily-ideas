import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var trades: [Trade]
    @AppStorage("wick.symbol") private var symbol = "$"
    @AppStorage("wick.startBalance") private var startBalance = 10000.0

    private var s: TradeStats.Summary { TradeStats.summary(trades) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if TradeStats.closed(trades).isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No closed trades",
                                   message: "Close a few trades to unlock your performance analytics.")
                        .glassCard().padding(20)
                } else {
                    VStack(spacing: 18) {
                        equityCard
                        statsGrid
                        strategyCard
                        symbolCard
                    }
                    .padding(20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Analytics")
        }
    }

    private var equityCard: some View {
        let curve = TradeStats.equityCurve(trades, startingBalance: startBalance)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow(text: "Equity curve")
                    Spacer()
                    if let last = curve.last {
                        Text(Money.string(last.equity, symbol: symbol))
                            .font(Brand.mono(14, weight: .semibold))
                            .foregroundStyle(last.equity >= startBalance ? Brand.live : Brand.danger)
                    }
                }
                Chart(curve) { p in
                    LineMark(x: .value("Date", p.date), y: .value("Equity", p.equity))
                        .foregroundStyle(Brand.magic).interpolationMethod(.monotone)
                    AreaMark(x: .value("Date", p.date), y: .value("Equity", p.equity))
                        .foregroundStyle(Brand.magic.opacity(0.12)).interpolationMethod(.monotone)
                    RuleMark(y: .value("Start", startBalance))
                        .foregroundStyle(Brand.text3.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .frame(height: 200)
                .chartYScale(domain: .automatic(includesZero: false))
                .accessibilityLabel("Account equity curve over time")
            }
        }
    }

    private var statsGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        let streak = TradeStats.currentStreak(trades)
        return LazyVGrid(columns: cols, spacing: 14) {
            tile("Win rate", "\(Int((s.winRate * 100).rounded()))%", s.winRate >= 0.5 ? Brand.live : Brand.warn)
            tile("Profit factor", s.profitFactor.map { String(format: "%.2f", $0) } ?? "—",
                 (s.profitFactor ?? 0) >= 1 ? Brand.live : Brand.danger)
            tile("Expectancy", Money.string(s.expectancy, symbol: symbol, showsSign: true),
                 s.expectancy >= 0 ? Brand.live : Brand.danger)
            tile("Avg win", Money.string(s.avgWin, symbol: symbol), Brand.live)
            tile("Avg loss", Money.string(s.avgLoss, symbol: symbol), Brand.danger)
            tile("Largest win", Money.string(s.largestWin, symbol: symbol), Brand.live)
            tile("Largest loss", Money.string(s.largestLoss, symbol: symbol), Brand.danger)
            tile("Streak", streak == 0 ? "—" : (streak > 0 ? "\(streak)W" : "\(-streak)L"),
                 streak >= 0 ? Brand.live : Brand.danger)
            tile("Avg hold", s.avgHold > 0 ? Format.duration(s.avgHold) : "—", Brand.info)
            tile("Wins / Losses", "\(s.wins) / \(s.losses)", Brand.text)
        }
    }

    private func tile(_ label: String, _ value: String, _ tint: Color) -> some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(value).font(Brand.mono(19, weight: .semibold)).foregroundStyle(tint)
                Text(label).font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var strategyCard: some View {
        let groups = TradeStats.byStrategy(trades)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "P/L by strategy")
                Chart(groups) { g in
                    BarMark(x: .value("P/L", g.pl), y: .value("Strategy", g.label))
                        .foregroundStyle(g.pl >= 0 ? Brand.live : Brand.danger)
                        .cornerRadius(4)
                        .annotation(position: g.pl >= 0 ? .trailing : .leading) {
                            Text("\(g.count)").font(.caption2).foregroundStyle(Brand.text3)
                        }
                }
                .frame(height: CGFloat(groups.count) * 34 + 20)
                .accessibilityLabel("Profit and loss broken down by strategy")
            }
        }
    }

    private var symbolCard: some View {
        let groups = TradeStats.bySymbol(trades)
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Top symbols")
                ForEach(groups) { g in
                    HStack {
                        Text(g.label).font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text)
                        Text("\(g.count) trade\(g.count == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(Brand.text3)
                        Spacer()
                        Text(Money.string(g.pl, symbol: symbol, showsSign: true))
                            .font(Brand.mono(14)).foregroundStyle(g.pl >= 0 ? Brand.live : Brand.danger)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
