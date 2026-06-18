import Foundation
import SwiftData

/// Inserts or updates the DailyResult row for a given Daily puzzle as the player progresses.
enum DailyResultStore {
    @MainActor
    static func upsert(
        context: ModelContext,
        puzzle: Puzzle,
        score: Int,
        wordsFound: Int,
        pangrams: Int,
        reachedGenius: Bool
    ) {
        let key = puzzle.dateKey
        let descriptor = FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.dateKey == key }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.score = score
            existing.wordsFound = wordsFound
            existing.pangrams = pangrams
            existing.reachedGenius = reachedGenius
        } else {
            let date = DateKey.date(from: key) ?? Date()
            let result = DailyResult(
                dateKey: key,
                score: score,
                wordsFound: wordsFound,
                pangrams: pangrams,
                reachedGenius: reachedGenius,
                date: date
            )
            context.insert(result)
        }
        try? context.save()
    }
}
