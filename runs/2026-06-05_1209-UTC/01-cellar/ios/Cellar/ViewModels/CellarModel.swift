import Foundation

/// Pure, testable logic for filtering/sorting the cellar and computing insights.
/// No SwiftUI or SwiftData imports — view models stay framework-light.
enum CellarModel {

    // MARK: - Filtering & sorting

    static func filtered(_ bottles: [Bottle],
                         search: String,
                         category: TastingCategory?) -> [Bottle] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return bottles.filter { bottle in
            if let category, bottle.category != category { return false }
            guard !query.isEmpty else { return true }
            return bottle.name.lowercased().contains(query)
                || bottle.producer.lowercased().contains(query)
                || bottle.origin.lowercased().contains(query)
        }
    }

    static func sorted(_ bottles: [Bottle], by order: SettingsStore.SortOrder) -> [Bottle] {
        switch order {
        case .recentlyAdded:
            return bottles.sorted { $0.createdAt > $1.createdAt }
        case .recentlyTasted:
            return bottles.sorted {
                ($0.lastTastedAt ?? .distantPast) > ($1.lastTastedAt ?? .distantPast)
            }
        case .name:
            return bottles.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .rating:
            return bottles.sorted { ($0.averageRating ?? -1) > ($1.averageRating ?? -1) }
        }
    }

    // MARK: - Insights

    struct Insights {
        var bottleCount: Int
        var tastingCount: Int
        var averageRating: Double?
        var byCategory: [(category: TastingCategory, count: Int)]
        var topFlavors: [(name: String, count: Int)]
        var highestRated: Bottle?
        var currentStreakDays: Int
    }

    static func insights(for bottles: [Bottle], calendar: Calendar = .current) -> Insights {
        let allTastings = bottles.flatMap(\.tastings)

        let avg: Double? = allTastings.isEmpty
            ? nil
            : Double(allTastings.reduce(0) { $0 + $1.rating }) / Double(allTastings.count)

        let byCategory: [(TastingCategory, Int)] = TastingCategory.allCases.compactMap { cat in
            let count = bottles.filter { $0.category == cat }.count
            return count > 0 ? (cat, count) : nil
        }

        var flavorCounts: [String: Int] = [:]
        for tasting in allTastings {
            for tag in tasting.flavorTags {
                flavorCounts[tag, default: 0] += 1
            }
        }
        let topFlavors = flavorCounts
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(6)
            .map { (name: $0.key, count: $0.value) }

        let highest = bottles
            .filter { $0.averageRating != nil }
            .max { ($0.averageRating ?? 0) < ($1.averageRating ?? 0) }

        return Insights(
            bottleCount: bottles.count,
            tastingCount: allTastings.count,
            averageRating: avg,
            byCategory: byCategory.map { (category: $0.0, count: $0.1) },
            topFlavors: Array(topFlavors),
            highestRated: highest,
            currentStreakDays: streak(from: allTastings.map(\.date), calendar: calendar)
        )
    }

    /// Consecutive days (ending today or yesterday) that have at least one tasting.
    static func streak(from dates: [Date], calendar: Calendar = .current) -> Int {
        guard !dates.isEmpty else { return 0 }
        let days = Set(dates.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: .now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
}
