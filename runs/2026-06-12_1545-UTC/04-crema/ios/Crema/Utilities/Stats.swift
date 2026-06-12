import Foundation

struct MethodCount: Identifiable { let method: BrewMethod; let count: Int; var id: BrewMethod { method } }
struct TasteCount: Identifiable { let taste: Taste; let count: Int; var id: Taste { taste } }
struct DayCount: Identifiable { let day: Date; let count: Int; var id: Date { day } }

enum BrewStats {
    static func all(_ beans: [Bean]) -> [Brew] { beans.flatMap(\.brews) }

    static func totalBrews(_ beans: [Bean]) -> Int { all(beans).count }

    static func averageRating(_ beans: [Bean]) -> Double? {
        let rated = all(beans).filter { $0.ratingHalf > 0 }
        guard !rated.isEmpty else { return nil }
        return rated.reduce(0.0) { $0 + $1.rating } / Double(rated.count)
    }

    static func byMethod(_ beans: [Bean]) -> [MethodCount] {
        var d = [BrewMethod: Int]()
        for b in all(beans) { d[b.method, default: 0] += 1 }
        return BrewMethod.allCases.compactMap { m in d[m].map { MethodCount(method: m, count: $0) } }
            .sorted { $0.count > $1.count }
    }

    static func tasteBreakdown(_ beans: [Bean]) -> [TasteCount] {
        var d = [Taste: Int]()
        for b in all(beans) { if let t = b.taste { d[t, default: 0] += 1 } }
        return Taste.allCases.compactMap { t in d[t].map { TasteCount(taste: t, count: $0) } }
    }

    static func favoriteBean(_ beans: [Bean]) -> Bean? {
        beans.filter { $0.bestBrew != nil }
            .max { ($0.bestBrew?.ratingHalf ?? 0) < ($1.bestBrew?.ratingHalf ?? 0) }
    }

    /// Daily brew counts over the last `n` days, oldest first.
    static func dailyCounts(_ beans: [Bean], days n: Int, today: Date = Date(),
                            calendar: Calendar = .current) -> [DayCount] {
        let start = calendar.startOfDay(for: today)
        let brews = all(beans)
        return (0..<n).reversed().compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: -offset, to: start) else { return nil }
            let c = brews.filter { calendar.isDate($0.date, inSameDayAs: d) }.count
            return DayCount(day: d, count: c)
        }
    }
}

enum Currency {
    static var code: String { UserDefaults.standard.string(forKey: "currencyCode") ?? Locale.current.currency?.identifier ?? "USD" }
    static func string(_ value: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = code
        f.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

enum Fmt {
    static func grams(_ g: Double) -> String {
        g.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(g))g" : String(format: "%.1fg", g)
    }
    static func date(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
    static func relativeDay(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: d)
    }
}
