import SwiftUI
import SwiftData
import Charts

struct AllocationView: View {
    @Query(sort: \Account.sortIndex) private var accounts: [Account]
    @AppStorage("currencyCode") private var currencyCode = "USD"

    private var assetSlices: [AllocationSlice] { NetWorthEngine.assetAllocation(accounts) }
    private var liabilitySlices: [AllocationSlice] { NetWorthEngine.liabilityAllocation(accounts) }
    private var assetTotal: Double { assetSlices.reduce(0) { $0 + $1.amount } }
    private var liabilityTotal: Double { liabilitySlices.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if assetSlices.isEmpty && liabilitySlices.isEmpty {
                    EmptyStateView(icon: "chart.pie.fill",
                                   title: "Nothing to break down yet",
                                   message: "Add some accounts with balances and Plumb will show how your wealth is allocated.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if !assetSlices.isEmpty {
                                allocationCard("Assets", assetSlices, assetTotal)
                            }
                            if !liabilitySlices.isEmpty {
                                allocationCard("Liabilities", liabilitySlices, liabilityTotal)
                            }
                            if assetTotal > 0 {
                                ratioCard
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Allocation")
        }
    }

    private func allocationCard(_ title: String, _ slices: [AllocationSlice], _ total: Double) -> some View {
        Card(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                Chart(slices) { slice in
                    SectorMark(angle: .value("Amount", slice.amount),
                               innerRadius: .ratio(0.62), angularInset: 1.5)
                        .foregroundStyle(Theme.chartColor(slice.colorIndex))
                        .cornerRadius(3)
                }
                .frame(height: 200)
                .chartBackground { proxy in
                    VStack(spacing: 1) {
                        Text(Money.compact(total, code: currencyCode))
                            .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
                        Text("total").font(Theme.rounded(11, .medium)).foregroundStyle(Theme.inkSoft)
                    }
                }
                .accessibilityLabel("\(title) allocation, total \(Money.format(total, code: currencyCode))")
                VStack(spacing: 10) {
                    ForEach(slices) { slice in
                        LegendRow(color: Theme.chartColor(slice.colorIndex),
                                  label: slice.category,
                                  value: Money.compact(slice.amount, code: currencyCode),
                                  pct: total > 0 ? "\(Int(slice.amount / total * 100))%" : "—")
                    }
                }
            }
        }
    }

    private var ratioCard: some View {
        let dti = assetTotal > 0 ? liabilityTotal / assetTotal : 0
        return Card {
            HStack(spacing: 14) {
                Image(systemName: dti < 0.4 ? "checkmark.seal.fill" : "scalemass.fill")
                    .font(.system(size: 22)).foregroundStyle(dti < 0.4 ? Theme.good : Theme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Debt-to-asset ratio: \(Int(dti * 100))%")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Text(dti < 0.4 ? "Healthy — your assets comfortably outweigh your debts."
                                   : "Your debts are a meaningful share of your assets. Paying them down lifts net worth.")
                        .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
        }
    }
}
