import SwiftUI
import SwiftData

/// Sold items, newest first, grouped by month with month profit subtotals.
struct SalesView: View {
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Item.sourcedDate, order: .reverse) private var items: [Item]

    private var sold: [Item] {
        items.filter { $0.status == .sold && $0.sale != nil }
            .sorted { ($0.sale?.soldDate ?? .distantPast) > ($1.sale?.soldDate ?? .distantPast) }
    }

    private var grouped: [(month: Date, items: [Item])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: sold) { item in
            calendar.dateInterval(of: .month, for: item.sale?.soldDate ?? Date())?.start ?? Date()
        }
        return groups.map { (month: $0.key, items: $0.value) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sold.isEmpty {
                    EmptyStateView(icon: "dollarsign.circle",
                                   title: "No sales yet",
                                   message: "When you record a sale on a listed item, the full ledger — price, fees, shipping, profit — lands here.")
                } else {
                    List {
                        ForEach(grouped, id: \.month) { group in
                            Section {
                                ForEach(group.items) { item in
                                    NavigationLink(value: item) {
                                        row(item)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(group.month.formatted(.dateTime.month(.wide).year()))
                                    Spacer()
                                    let monthProfit = group.items.compactMap { ProfitEngine.profit(item: $0) }.reduce(0, +)
                                    Text(ProfitEngine.money(monthProfit))
                                        .foregroundStyle(Theme.profitColor(monthProfit))
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Sales")
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }

    private func row(_ item: Item) -> some View {
        let profit = ProfitEngine.profit(item: item) ?? 0
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let sale = item.sale {
                        Text(sale.platform.label)
                        if let days = ProfitEngine.daysToSell(item: item) {
                            Text("· \(days)d to sell")
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.inkSoft(scheme))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(ProfitEngine.money(profit))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.profitColor(profit))
                if let roi = ProfitEngine.roi(item: item) {
                    Text("\(Int((roi * 100).rounded()))% ROI")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), profit \(ProfitEngine.money(profit))")
    }
}
