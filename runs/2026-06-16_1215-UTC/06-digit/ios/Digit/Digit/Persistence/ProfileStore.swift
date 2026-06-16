import Foundation
import SwiftData

/// Persistence helpers that bridge SwiftData models with the pure engines.
@MainActor
enum ProfileStore {

    /// Find (or lazily create) the FactStat for a fact within a profile.
    static func factStat(for question: Question,
                         in profile: Profile,
                         context: ModelContext) -> FactStat {
        if let found = profile.facts.first(where: {
            $0.op == question.op && $0.a == question.a && $0.b == question.b
        }) {
            return found
        }
        let stat = FactStat(op: question.op, a: question.a, b: question.b)
        stat.profile = profile
        context.insert(stat)
        return stat
    }

    /// Apply one answer outcome to the persistent fact record.
    static func record(outcome: AnswerOutcome,
                       question: Question,
                       in profile: Profile,
                       context: ModelContext) {
        let stat = factStat(for: question, in: profile, context: context)
        stat.timesSeen += 1
        if outcome.correct { stat.timesCorrect += 1 }
        stat.lastSeen = .now
        let updated = FactEngine.updatedMastery(currentLevel: stat.masteryLevel,
                                                currentFastestMs: stat.fastestMs,
                                                outcome: outcome)
        stat.masteryLevel = updated.level
        stat.fastestMs = updated.fastestMs
    }

    /// Build the FactState lookup the engine needs for adaptive selection.
    static func factStates(for profile: Profile) -> [String: FactEngine.FactState] {
        var map: [String: FactEngine.FactState] = [:]
        for f in profile.facts {
            let state = FactEngine.FactState(op: f.op, a: f.a, b: f.b,
                                             masteryLevel: f.masteryLevel,
                                             timesSeen: f.timesSeen,
                                             lastSeen: f.lastSeen)
            map[state.identityKey] = state
        }
        return map
    }

    /// Persist a finished session.
    static func saveSession(profile: Profile,
                            opRaw: String,
                            levelIndex: Int,
                            total: Int,
                            correct: Int,
                            durationSec: Double,
                            stars: Int,
                            context: ModelContext) {
        let session = Session(opRaw: opRaw, levelIndex: levelIndex, total: total,
                              correct: correct, durationSec: durationSec, starsEarned: stars)
        session.profile = profile
        context.insert(session)
        try? context.save()
    }

    /// Reset a profile's learning data (facts + sessions) without deleting the profile.
    static func resetProgress(for profile: Profile, context: ModelContext) {
        for f in profile.facts { context.delete(f) }
        for s in profile.sessions { context.delete(s) }
        profile.currentLevelIndex = 0
        try? context.save()
    }

    /// Advance a profile's level when its current level is passed.
    static func advanceLevelIfReady(_ profile: Profile, context: ModelContext) {
        let level = Curriculum.level(at: profile.currentLevelIndex)
        if ProgressEngine.isLevelPassed(level, facts: profile.facts),
           profile.currentLevelIndex + 1 < Curriculum.count {
            profile.currentLevelIndex += 1
            try? context.save()
        }
    }
}
