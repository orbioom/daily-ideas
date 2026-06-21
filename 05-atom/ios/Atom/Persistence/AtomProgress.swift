import Foundation
import SwiftData

@Model
final class AtomProgress {
    var quizzesCompleted: Int = 0
    var totalCorrect: Int = 0
    var bestStreak: Int = 0
    var currentStreak: Int = 0
    var sessionData: Data = Data()        // JSON [QuizSessionRecord]
    var missedElementIds: Data = Data()   // JSON [Int] (atomic numbers)

    init() {}

    struct QuizSessionRecord: Codable, Identifiable {
        let id: UUID
        let date: Date
        let mode: String
        let correct: Int
        let total: Int
        var accuracy: Double { total > 0 ? Double(correct) / Double(total) * 100 : 0 }

        init(date: Date, mode: String, correct: Int, total: Int) {
            self.id = UUID()
            self.date = date
            self.mode = mode
            self.correct = correct
            self.total = total
        }
    }

    // MARK: - Session management

    var sessions: [QuizSessionRecord] {
        get {
            (try? JSONDecoder().decode([QuizSessionRecord].self, from: sessionData)) ?? []
        }
    }

    func appendSession(_ record: QuizSessionRecord) {
        var current = sessions
        current.append(record)
        // Keep last 50 sessions
        if current.count > 50 {
            current = Array(current.suffix(50))
        }
        sessionData = (try? JSONEncoder().encode(current)) ?? Data()
    }

    // MARK: - Missed elements

    var missedElementIdList: [Int] {
        (try? JSONDecoder().decode([Int].self, from: missedElementIds)) ?? []
    }

    func recordMissed(elementId: Int) {
        var ids = missedElementIdList
        ids.append(elementId)
        if ids.count > 200 { ids = Array(ids.suffix(200)) }
        missedElementIds = (try? JSONEncoder().encode(ids)) ?? Data()
    }

    func topMissedElementIds(limit: Int = 5) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for id in missedElementIdList {
            counts[id, default: 0] += 1
        }
        return counts
    }

    func recordQuizResult(correct: Int, total: Int, mode: String, engine: QuizEngine) {
        quizzesCompleted += 1
        totalCorrect += correct
        if engine.bestStreak > bestStreak {
            bestStreak = engine.bestStreak
        }
        let record = QuizSessionRecord(date: Date(), mode: mode, correct: correct, total: total)
        appendSession(record)
        // Record missed elements
        for ans in engine.sessionHistory where !ans.wasCorrect {
            recordMissed(elementId: ans.element.id)
        }
    }

    // MARK: - Computed stats

    var overallAccuracy: Double {
        let totalQ = sessions.reduce(0) { $0 + $1.total }
        let totalC = sessions.reduce(0) { $0 + $1.correct }
        guard totalQ > 0 else { return 0 }
        return Double(totalC) / Double(totalQ) * 100
    }

    var last10Sessions: [QuizSessionRecord] {
        Array(sessions.suffix(10))
    }

    func accuracy(for mode: QuizEngine.QuizMode) -> Double {
        let modeSessions = sessions.filter { $0.mode == mode.rawValue }
        let total = modeSessions.reduce(0) { $0 + $1.total }
        let correct = modeSessions.reduce(0) { $0 + $1.correct }
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
}
