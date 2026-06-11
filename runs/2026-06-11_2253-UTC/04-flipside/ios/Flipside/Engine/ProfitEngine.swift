import Foundation

/// Pure reselling math. No UI, no I/O.
enum ProfitEngine {

    /// Net profit on a sold item: sale − fees − shipping − cost of goods.
    static func profit(item: Item) -> Double? {
        guard let sale = item.sale else { return nil }
        return sale.soldPrice - sale.fees - sale.shipping - item.cost
    }

    /// Return on investment (profit ÷ cost). Nil when cost is zero (free finds).
    static func roi(item: Item) -> Double? {
        guard let p = profit(item: item), item.cost > 0 else { return nil }
        return p / item.cost
    }

    /// Days from listing (or sourcing, if never marked listed) to sale.
    static func daysToSell(item: Item) -> Int? {
        guard let sale = item.sale else { return nil }
        let start = item.listedDate ?? item.sourcedDate
        return max(Int(sale.soldDate.timeIntervalSince(start) / 86_400), 0)
    }

    // MARK: Portfolio rollups

    struct Summary {
        let activeCount: Int
        let activeInvested: Double
        let potentialValue: Double
        let soldCount: Int
        let totalRevenue: Double
        let totalProfit: Double
        let averageROI: Double?
        let averageDaysToSell: Double?
    }

    static func summary(items: [Item]) -> Summary {
        let active = items.filter { $0.status != .sold }
        let sold = items.filter { $0.status == .sold && $0.sale != nil }
        let profits = sold.compactMap { profit(item: $0) }
        let rois = sold.compactMap { roi(item: $0) }
        let days = sold.compactMap { daysToSell(item: $0) }
        return Summary(
            activeCount: active.count,
            activeInvested: active.reduce(0) { $0 + $1.cost },
            potentialValue: active.filter { $0.status == .listed }.reduce(0) { $0 + $1.listPrice },
            soldCount: sold.count,
            totalRevenue: sold.compactMap(\.sale).reduce(0) { $0 + $1.soldPrice },
            totalProfit: profits.reduce(0, +),
            averageROI: rois.isEmpty ? nil : rois.reduce(0, +) / Double(rois.count),
            averageDaysToSell: days.isEmpty ? nil : Double(days.reduce(0, +)) / Double(days.count))
    }

    /// Profit per calendar month for the trailing `months`.
    static func monthlyProfit(items: [Item], months: Int = 6,
                              calendar: Calendar = .current, now: Date = Date()) -> [(month: Date, profit: Double)] {
        guard let thisMonth = calendar.dateInterval(of: .month, for: now)?.start else { return [] }
        var buckets: [Date: Double] = [:]
        var starts: [Date] = []
        for i in 0..<months {
            if let start = calendar.date(byAdding: .month, value: -i, to: thisMonth) {
                buckets[start] = 0
                starts.append(start)
            }
        }
        for item in items {
            guard let sale = item.sale, let p = profit(item: item),
                  let month = calendar.dateInterval(of: .month, for: sale.soldDate)?.start,
                  buckets[month] != nil else { continue }
            buckets[month, default: 0] += p
        }
        return starts.sorted().map { (month: $0, profit: buckets[$0] ?? 0) }
    }

    /// Sold-count + profit grouped by platform, best profit first.
    static func platformBreakdown(items: [Item]) -> [(platform: Platform, count: Int, profit: Double)] {
        var data: [Platform: (count: Int, profit: Double)] = [:]
        for item in items {
            guard let sale = item.sale, let p = profit(item: item) else { continue }
            let prev = data[sale.platform] ?? (0, 0)
            data[sale.platform] = (prev.count + 1, prev.profit + p)
        }
        return data.map { (platform: $0.key, count: $0.value.count, profit: $0.value.profit) }
            .sorted { $0.profit > $1.profit }
    }

    /// Listed items that have sat longer than `staleDays`, oldest first.
    static func staleListings(items: [Item], staleDays: Int = 60, now: Date = Date()) -> [Item] {
        items.filter { item in
            guard item.status == .listed else { return false }
            let listed = item.listedDate ?? item.sourcedDate
            return now.timeIntervalSince(listed) > Double(staleDays) * 86_400
        }
        .sorted { ($0.listedDate ?? $0.sourcedDate) < ($1.listedDate ?? $1.sourcedDate) }
    }

    /// Share of ever-listed items that sold (sell-through).
    static func sellThroughRate(items: [Item]) -> Double? {
        let listedOrSold = items.filter { $0.status == .listed || $0.status == .sold }
        guard !listedOrSold.isEmpty else { return nil }
        let sold = listedOrSold.filter { $0.status == .sold }
        return Double(sold.count) / Double(listedOrSold.count)
    }

    // MARK: Formatting

    static func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }
}
