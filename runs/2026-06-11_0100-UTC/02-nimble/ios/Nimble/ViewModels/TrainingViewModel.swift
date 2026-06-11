import SwiftUI
import SwiftData

@Observable
class TrainingViewModel {
    private(set) var todayResult: DailyResult?
    private(set) var completedGameTypes: Set<GameType> = []
    private(set) var isLoading = true

    func load(modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.date == today }
        )
        if let result = try? modelContext.fetch(descriptor).first {
            todayResult = result
        }

        let sessionDescriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate { $0.date >= today }
        )
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        completedGameTypes = Set(sessions.compactMap { GameType(rawValue: $0.gameTypeRaw) })
        isLoading = false
    }

    func recordSession(gameType: GameType, score: Int, duration: Double, level: Int,
                       modelContext: ModelContext) {
        let session = GameSession(gameType: gameType, score: score, duration: duration, level: level)
        modelContext.insert(session)

        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.date == today }
        )
        let result: DailyResult
        if let existing = try? modelContext.fetch(descriptor).first {
            result = existing
        } else {
            result = DailyResult(date: Date())
            modelContext.insert(result)
        }
        result.totalScore += score
        result.gamesPlayed += 1
        todayResult = result
        completedGameTypes.insert(gameType)
    }

    var todayAllDone: Bool { completedGameTypes.count >= GameType.allCases.count }

    var todayProgressFraction: Double {
        Double(completedGameTypes.count) / Double(GameType.allCases.count)
    }
}
