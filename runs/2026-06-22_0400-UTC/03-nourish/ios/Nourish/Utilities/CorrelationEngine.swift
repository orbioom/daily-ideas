import Foundation

// MARK: - CorrelationEngine

/// Pure Swift correlation engine — no ML required.
/// Scores each food by how often a symptom appears within `windowHours` after eating it.
struct CorrelationEngine {

    struct TriggerResult: Identifiable {
        var id: String { food }
        let food: String
        let score: Double      // 0.0 – 1.0
        let count: Int         // symptom occurrences after eating
        let totalEaten: Int
        let allergenTags: [String]

        var confidenceLabel: String {
            switch score {
            case 0.75...: return "High"
            case 0.50..<0.75: return "Medium"
            case 0.25..<0.50: return "Low"
            default: return "Weak"
            }
        }
    }

    /// Returns the top suspected food triggers sorted by correlation score.
    /// - Parameters:
    ///   - foodLogs: All food log entries.
    ///   - symptomLogs: All symptom entries.
    ///   - windowHours: How many hours after eating to check for symptoms.
    ///   - topN: Maximum results to return.
    /// - Returns: Array of TriggerResult sorted descending by score, or empty if insufficient data.
    static func topTriggers(
        foodLogs: [FoodLogEntry],
        symptomLogs: [SymptomEntry],
        windowHours: Double = 24.0,
        topN: Int = 5
    ) -> [TriggerResult] {
        guard foodLogs.count >= 3 else { return [] }
        guard !symptomLogs.isEmpty else { return [] }

        let windowSeconds = windowHours * 3600.0

        // Group food logs by food name
        var foodGroups: [String: [FoodLogEntry]] = [:]
        for entry in foodLogs {
            foodGroups[entry.foodName, default: []].append(entry)
        }

        var results: [TriggerResult] = []

        for (foodName, entries) in foodGroups {
            guard !entries.isEmpty else { continue }
            let totalEaten = entries.count

            // Count symptom occurrences within window after each eating event
            var symptomCount = 0
            for foodEntry in entries {
                let windowStart = foodEntry.date.timeIntervalSinceReferenceDate
                let windowEnd = windowStart + windowSeconds

                let symptomsInWindow = symptomLogs.filter { symptom in
                    let t = symptom.date.timeIntervalSinceReferenceDate
                    // Allow a 4-hour minimum gap (acute reaction only, not simultaneous)
                    return t >= (windowStart + 4 * 3600) && t <= windowEnd
                }

                if !symptomsInWindow.isEmpty {
                    symptomCount += 1
                }
            }

            guard totalEaten > 0 else { continue }
            let score = Double(symptomCount) / Double(totalEaten)

            // Only include foods that have at least one correlation hit
            guard symptomCount > 0 else { continue }

            let tags = entries.first?.allergenTags ?? []
            results.append(TriggerResult(
                food: foodName,
                score: score,
                count: symptomCount,
                totalEaten: totalEaten,
                allergenTags: tags
            ))
        }

        // Sort descending by score, then by count for ties
        results.sort { lhs, rhs in
            if abs(lhs.score - rhs.score) > 0.001 {
                return lhs.score > rhs.score
            }
            return lhs.count > rhs.count
        }

        return Array(results.prefix(topN))
    }

    /// Returns symptom frequency grouped by day for the past `days` days.
    static func symptomsByDay(
        symptomLogs: [SymptomEntry],
        days: Int = 14
    ) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = symptomLogs.filter { entry in
                entry.date >= day && entry.date < nextDay
            }.count
            return (date: day, count: count)
        }
    }

    /// Returns food log entries grouped by day for the past `days` days.
    static func foodLogsByDay(
        foodLogs: [FoodLogEntry],
        days: Int = 14
    ) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = foodLogs.filter { entry in
                entry.date >= day && entry.date < nextDay
            }.count
            return (date: day, count: count)
        }
    }

    /// Returns the top N most frequent symptoms.
    static func mostFrequentSymptoms(
        symptomLogs: [SymptomEntry],
        topN: Int = 6
    ) -> [(symptom: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in symptomLogs {
            counts[entry.symptomName, default: 0] += 1
        }
        return counts
            .map { (symptom: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(topN)
            .map { $0 }
    }

    /// Returns average symptom severity over the last N days.
    static func averageSeverity(symptomLogs: [SymptomEntry], days: Int = 7) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = symptomLogs.filter { $0.date >= cutoff }
        guard !recent.isEmpty else { return 0.0 }
        let total = recent.reduce(0) { $0 + $1.severity }
        return Double(total) / Double(recent.count)
    }
}
