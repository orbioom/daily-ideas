import Foundation
import SwiftData

/// Derives everything the Today screen shows from the current progress + sessions.
@MainActor
@Observable
final class TodayViewModel {
    private(set) var wordOfDay: VocabWord?
    private(set) var dueCount = 0
    private(set) var streak = 0
    private(set) var todayProgress: WordProgress?
    private(set) var isLoading = true

    /// Recomputes all derived values. Cheap; safe to call on appear.
    func load(store: ProgressStore, now: Date = Date()) {
        isLoading = true
        let progress = store.allProgress()
        let sessions = store.allSessions()

        let learnedIDs = Set(progress.filter { $0.learned }.map { $0.wordID })
        wordOfDay = LexemeEngine.wordOfTheDay(on: now, learnedIDs: learnedIDs)
        dueCount = progress.filter { LexemeEngine.isDue($0, now: now) }.count
        streak = LexemeEngine.streak(sessions, now: now)
        if let w = wordOfDay {
            todayProgress = store.existingProgress(for: w.id)
        } else {
            todayProgress = nil
        }
        isLoading = false
    }
}
