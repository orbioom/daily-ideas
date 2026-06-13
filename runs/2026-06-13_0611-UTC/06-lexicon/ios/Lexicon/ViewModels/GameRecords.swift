import Foundation
import SwiftData

enum GameRecords {
    /// Insert a finished game, deduping daily/archive games by their dayKey.
    @MainActor
    static func record(_ context: ModelContext, dayKey: String, answer: String,
                       guesses: [String], won: Bool, hardMode: Bool) {
        if !dayKey.isEmpty {
            let key = dayKey
            var desc = FetchDescriptor<GameRecord>(predicate: #Predicate { $0.dayKey == key })
            desc.fetchLimit = 1
            if let existing = try? context.fetch(desc), !existing.isEmpty { return }
        }
        let date = WordGame.date(fromDayKey: dayKey) ?? .now
        context.insert(GameRecord(dayKey: dayKey, date: dayKey.isEmpty ? .now : date,
                                  answer: answer, guesses: guesses, won: won, hardMode: hardMode))
        try? context.save()
    }
}
