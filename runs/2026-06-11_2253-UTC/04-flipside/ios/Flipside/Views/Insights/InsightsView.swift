import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("staleDays") private var staleDays = 60
    @Query private var items: [Item]

    private var summary: ProfitEngine.Summary { ProfitEngine.summary(items: items) }

    var body: some View {
        NavigationStack {
            Group {
                if summary.soldCount == 0 && summary.activeCount == 0 {
                    EmptyStateView(icon: "chart.pie",
                                   title: "Numbers arrive with flips",
                                   message: "Add inventory and record a sale or two — Flipside will chart profit, ROI, platforms, and stale listings here.")
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            tiles
                            if summary.soldCount > 0 {
                                profitChart
                                platformCard
                            }
                            staleCard
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Insights")
        }
    }

    private var tiles: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                tile(title: "Total profit", value: ProfitEngine.money(summary.totalProfit),
                     color: Theme.profitColor(summary.totalProfit))
                tile(title: "Revenue", value: ProfitEngine.money(summary.totalRevenue))
            }
            HStack(spacing: 12) {
                tile(title: "Avg ROI",
                     value: summary.averageROI.map { "\(Int(($0 * 100).rounded()))%" } ?? "—")
                tile(title: "Avg days to sell",
                     value: summary.averageDaysToSell.map { String(format: "%.0f", $0) } ?? "—")
                tile(title: "Sell-through",
                     value: ProfitEngine.sellThroughRate(items: items).map { "\(Int(($0 * 100).rounded()))%" } ?? "—")
            }
            HStack(spacing: 12) {
                tile(title: "Active items", value: "\(summary.activeCount)")
                tile(title: "Cash tied up", value: ProfitEngine.money(summary.activeInvested))
                tile(title: "Listed value", value: ProfitEngine.money(summary.potentialValue))
            }
        }
    }

    private func tile(title: String, value: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft(scheme))
            Text(value)
                .font(Theme.display(17))
                .foregroundStyle(color ?? Theme.ink(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var profitChart: some View {
        let monthly = ProfitEngine.monthlyProfit(items: items)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Profit by month").font(.headline)
            Chart(monthly, id: \.month) { entry in
                BarMark(x: .value("Month", entry.month, unit: .month),
                        y: .value("Profit", entry.profit))
                .foregroundStyle(entry.profit >= 0 ? Theme.teal : Color.red)
                .cornerRadius(4)
            }
            .frame(height: 170)
            .accessibilityLabel("Bar chart of monthly profit for the last 6 months")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .flipCard()
    }

    private var platformCard: some View {
        let breakdown = ProfitEngine.platformBreakdown(items: items)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Where the money is").font(.headline)
            if breakdown.isEmpty {
                Text("Record sales to compare platforms.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                Chart(breakdown, id: \.platform) { entry in
                    BarMark(x: .value("Profit", entry.profit),
                            y: .value("Platform", entry.platform.label))
                    .foregroundStyle(Theme.tangerine)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(ProfitEngine.money(entry.profit))
                            .font(.caption2)
                            .foregroundStyle(Theme.inkSoft(scheme))
                    }
                }
                .frame(height: CGFloat(breakdown.count) * 44 + 20)
                .accessibilityLabel("Horizontal bars of profit per platform")
                ForEach(breakdown, id: \.platform) { entry in
                    HStack {
                        Text(entry.platform.label)
                            .font(.caption)
                        Spacer()
                        Text("\(entry.count) sale\(entry.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft(scheme))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .flipCard()
    }

    private var staleCard: some View {
        let stale = ProfitEngine.staleListings(items: items, staleDays: staleDays)
        let deathPile = items.filter { $0.status == .sourced }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Needs attention").font(.headline)
            if stale.isEmpty && deathPile.isEmpty {
                Label("Everything is listed and moving. Clean shop.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.teal)
            } else {
                if !deathPile.isEmpty {
                    Label("\(deathPile.count) item\(deathPile.count == 1 ? "" : "s") in the death pile (sourced, never listed) worth \(ProfitEngine.money(deathPile.reduce(0) { $0 + $1.cost })) in sunk cost.",
                          systemImage: "shippingbox")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mustard)
                }
                ForEach(stale.prefix(5)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let listed = item.listedDate {
                                Text("Listed \(listed.formatted(date: .abbreviated, time: .omitted)) — consider a price drop")
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft(scheme))
                            }
                        }
                        Spacer()
                        Text(ProfitEngine.money(item.listPrice))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.tangerine)
                    }
                }
                if stale.count > 5 {
                    Text("+ \(stale.count - 5) more stale listing\(stale.count - 5 == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .flipCard()
    }
}
