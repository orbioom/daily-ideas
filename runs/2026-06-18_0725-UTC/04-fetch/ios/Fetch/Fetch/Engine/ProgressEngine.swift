import Foundation

/// Pure, guarded analytics over a single dog's progress and sessions.
/// No force-unwraps, no unguarded division — safe on any data shape.
enum ProgressEngine {

    // MARK: - Status helpers

    static func progress(for dog: Dog, trickId: String) -> TrickProgress? {
        dog.progress.first { $0.trickId == trickId }
    }

    static func status(for dog: Dog, trickId: String) -> TrickStatus {
        progress(for: dog, trickId: trickId)?.status ?? .notStarted
    }

    static func counts(for dog: Dog) -> [TrickStatus: Int] {
        var result: [TrickStatus: Int] = [:]
        for status in TrickStatus.allCases { result[status] = 0 }
        for p in dog.progress {
            result[p.status, default: 0] += 1
        }
        return result
    }

    /// Mastery percentage across the entire static catalog (0...1).
    static func masteryFraction(for dog: Dog) -> Double {
        let total = TrickCatalog.all.count
        guard total > 0 else { return 0 }
        let mastered = dog.progress.filter { $0.status == .mastered && TrickCatalog.trick($0.trickId) != nil }.count
        return min(1, Double(mastered) / Double(total))
    }

    static func masteredCount(for dog: Dog) -> Int {
        dog.progress.filter { $0.status == .mastered }.count
    }

    static func inProgressCount(for dog: Dog) -> Int {
        dog.progress.filter { $0.status == .learning || $0.status == .practicing }.count
    }

    // MARK: - Streak

    /// Number of consecutive days (ending today or yesterday) with at least one session.
    static func trainingStreak(for dog: Dog, now: Date = Date()) -> Int {
        let cal = Calendar.current
        let days = Set(dog.sessions.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = cal.startOfDay(for: now)

        // Allow the streak to count if the most recent training was today or yesterday.
        if !days.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func trainedToday(for dog: Dog, now: Date = Date()) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        return dog.sessions.contains { cal.startOfDay(for: $0.date) == today }
    }

    static func minutesToday(for dog: Dog, now: Date = Date()) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let secs = dog.sessions
            .filter { cal.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.durationSec }
        return secs / 60
    }

    // MARK: - Suggestions

    /// Whether all prerequisites for a trick are at least "practicing" for this dog.
    static func prerequisitesMet(_ trick: Trick, for dog: Dog) -> Bool {
        for preId in trick.prerequisites {
            let s = status(for: dog, trickId: preId)
            if s.rank < TrickStatus.practicing.rank { return false }
        }
        return true
    }

    /// Suggested next tricks: unmastered, prerequisites met, easier first.
    /// Prioritizes tricks already in progress, then brand-new ready tricks.
    static func suggestedTricks(for dog: Dog, limit: Int = 3) -> [Trick] {
        let candidates = TrickCatalog.all.filter { trick in
            let s = status(for: dog, trickId: trick.id)
            guard s != .mastered else { return false }
            return prerequisitesMet(trick, for: dog)
        }

        let sorted = candidates.sorted { a, b in
            let sa = status(for: dog, trickId: a.id).rank
            let sb = status(for: dog, trickId: b.id).rank
            if sa != sb { return sa > sb }                 // in-progress before not-started
            if a.difficulty != b.difficulty { return a.difficulty < b.difficulty } // easier first
            return a.name < b.name
        }

        return Array(sorted.prefix(max(0, limit)))
    }

    // MARK: - Programs

    /// Fraction (0...1) of a program's tricks that this dog has mastered.
    static func programProgress(_ program: TrainingProgram, for dog: Dog) -> Double {
        let ids = program.trickIDs
        guard !ids.isEmpty else { return 0 }
        let mastered = ids.filter { status(for: dog, trickId: $0) == .mastered }.count
        return min(1, Double(mastered) / Double(ids.count))
    }

    static func programMasteredCount(_ program: TrainingProgram, for dog: Dog) -> Int {
        program.trickIDs.filter { status(for: dog, trickId: $0) == .mastered }.count
    }
}
