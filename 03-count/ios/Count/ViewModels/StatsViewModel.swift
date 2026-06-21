import SwiftUI
import SwiftData

@Observable final class StatsViewModel {
    var records: [TrainingRecord] = []

    func load(from context: ModelContext) {
        let desc = FetchDescriptor<TrainingRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        records = (try? context.fetch(desc)) ?? []
    }

    var totalAnswered: Int { records.count }
    var totalCorrect: Int { records.filter(\.isCorrect).count }
    var overallAccuracy: Double {
        totalAnswered == 0 ? 0 : Double(totalCorrect) / Double(totalAnswered)
    }

    struct ScenarioStat: Identifiable {
        let id = UUID()
        let scenario: String
        let attempts: Int
        let correct: Int
        var accuracy: Double { attempts == 0 ? 0 : Double(correct) / Double(attempts) }
    }

    struct DailyStat: Identifiable {
        let id = UUID()
        let date: Date
        let accuracy: Double
        let count: Int
    }

    var hardestScenarios: [ScenarioStat] {
        var dict: [String: (Int, Int)] = [:]
        for r in records {
            let (a, c) = dict[r.scenario] ?? (0, 0)
            dict[r.scenario] = (a + 1, c + (r.isCorrect ? 1 : 0))
        }
        return dict.map { ScenarioStat(scenario: $0.key, attempts: $0.value.0, correct: $0.value.1) }
            .filter { $0.attempts >= 3 }
            .sorted { $0.accuracy < $1.accuracy }
            .prefix(10)
            .map { $0 }
    }

    var last7DaysStats: [DailyStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0...6).reversed().compactMap { offset -> DailyStat? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let dayRecords = records.filter { $0.date >= day && $0.date < nextDay }
            let count = dayRecords.count
            let correct = dayRecords.filter(\.isCorrect).count
            let accuracy = count == 0 ? 0.0 : Double(correct) / Double(count)
            return DailyStat(date: day, accuracy: accuracy, count: count)
        }
    }

    var currentStreak: Int {
        var streak = 0
        for record in records {
            if record.isCorrect {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}
