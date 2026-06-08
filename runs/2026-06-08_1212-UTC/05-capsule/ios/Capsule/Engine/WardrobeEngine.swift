import Foundation

/// Pure wardrobe analytics: value, cost-per-wear, most/least/neglected, and
/// category/color breakdowns over a set of items.
struct WardrobeEngine {
    let calendar: Calendar
    init(calendar: Calendar = .current) { self.calendar = calendar }

    // MARK: - Wearing an outfit

    /// The wear logs that should be created when an outfit is worn on a date —
    /// one per item. (The caller inserts them into the context.)
    func wearLogs(for outfit: Outfit, on date: Date) -> [(item: ClothingItem, date: Date)] {
        outfit.items.map { (item: $0, date: date) }
    }

    // MARK: - Totals

    func totalValue(_ items: [ClothingItem]) -> Double {
        items.reduce(0) { $0 + $1.cost }
    }

    func totalWears(_ items: [ClothingItem]) -> Int {
        items.reduce(0) { $0 + $1.wearCount }
    }

    /// Average cost-per-wear across items that have a cost.
    func averageCostPerWear(_ items: [ClothingItem]) -> Double? {
        let withCost = items.filter { $0.cost > 0 }
        guard !withCost.isEmpty else { return nil }
        let sum = withCost.reduce(0.0) { $0 + ($1.costPerWear ?? 0) }
        return sum / Double(withCost.count)
    }

    // MARK: - Rankings

    func mostWorn(_ items: [ClothingItem], limit: Int = 5) -> [ClothingItem] {
        items.filter { $0.wearCount > 0 }
            .sorted { $0.wearCount > $1.wearCount }
            .prefix(limit).map { $0 }
    }

    func bestValue(_ items: [ClothingItem], limit: Int = 5) -> [ClothingItem] {
        items.filter { ($0.costPerWear ?? .infinity) < .infinity }
            .sorted { ($0.costPerWear ?? .infinity) < ($1.costPerWear ?? .infinity) }
            .prefix(limit).map { $0 }
    }

    /// Items never worn, or not worn in `days` days. Sorted oldest-first.
    func neglected(_ items: [ClothingItem], days: Int = 60, asOf today: Date = .now) -> [ClothingItem] {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: today) ?? today
        return items.filter { item in
            guard let last = item.lastWorn else { return true }
            return last < cutoff
        }
        .sorted { ($0.lastWorn ?? .distantPast) < ($1.lastWorn ?? .distantPast) }
    }

    // MARK: - Breakdowns

    struct CategoryCount: Identifiable {
        let id = UUID()
        let category: ItemCategory
        let count: Int
        let value: Double
    }

    func byCategory(_ items: [ClothingItem]) -> [CategoryCount] {
        ItemCategory.allCases.compactMap { cat in
            let inCat = items.filter { $0.category == cat }
            guard !inCat.isEmpty else { return nil }
            return CategoryCount(category: cat, count: inCat.count, value: totalValue(inCat))
        }
        .sorted { $0.count > $1.count }
    }

    struct ColorCount: Identifiable {
        let id = UUID()
        let colorHex: UInt32
        let name: String
        let count: Int
    }

    func byColor(_ items: [ClothingItem]) -> [ColorCount] {
        var map: [UInt32: (String, Int)] = [:]
        for i in items {
            let existing = map[i.colorHex] ?? (i.colorName, 0)
            map[i.colorHex] = (existing.0.isEmpty ? i.colorName : existing.0, existing.1 + 1)
        }
        return map.map { ColorCount(colorHex: $0.key, name: $0.value.0, count: $0.value.1) }
            .sorted { $0.count > $1.count }
    }
}
