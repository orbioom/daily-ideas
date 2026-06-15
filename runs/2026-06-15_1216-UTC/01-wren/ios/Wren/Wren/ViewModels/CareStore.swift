import Foundation
import SwiftData

/// Centralized, crash-proof mutations against SwiftData. Views call these methods
/// rather than mutating models directly so currency, energy, XP, journeys and
/// streaks all stay consistent. All saves are guarded — failures surface as thrown
/// errors that callers can present calmly.
@MainActor
struct CareStore {
    let context: ModelContext

    enum StoreError: LocalizedError {
        case alreadyCompletedToday
        case notEnoughEnergy
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .alreadyCompletedToday: return "That goal is already done for today."
            case .notEnoughEnergy: return "Your Wren needs more energy before this journey."
            case .saveFailed: return "Couldn't save your change. Please try again."
            }
        }
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            throw StoreError.saveFailed
        }
    }

    // MARK: - Completing a goal

    struct CompletionResult {
        let pebbles: Int
        let energy: Int
        let xp: Int
        let leveledUpTo: Int?
        let journeyCompleted: Journey?
    }

    /// Complete a goal for today. Guards against double-completion. Applies pebbles,
    /// energy, XP, advances the active journey, and may complete it (awarding a reward).
    @discardableResult
    func completeGoal(_ goal: SelfCareGoal, companion: Companion, on date: Date = Date()) throws -> CompletionResult {
        guard !goal.isCompleted(on: date) else { throw StoreError.alreadyCompletedToday }

        let award = CareEngine.award(for: goal)

        // First, apply lazy energy decay so neglect is honored, then add reward energy.
        let decayed = CareEngine.decayedEnergy(current: companion.energy, lastTendedAt: companion.lastTendedAt, now: date)

        let completion = GoalCompletion(
            date: date,
            pebblesAwarded: award.pebbles,
            energyAwarded: award.energy,
            goal: goal
        )
        context.insert(completion)

        let beforeLevel = CareEngine.levelProgress(totalXP: companion.xp).level
        companion.pebbles = max(0, companion.pebbles + award.pebbles)
        companion.energy = CareEngine.clampEnergy(decayed + award.energy)
        companion.xp = max(0, companion.xp + award.xp)
        companion.lastTendedAt = date
        let afterLevel = CareEngine.levelProgress(totalXP: companion.xp).level
        let leveledUpTo = afterLevel > beforeLevel ? afterLevel : nil

        // Advance the active journey, if any.
        var completedJourney: Journey?
        if let journey = try activeJourney(), !journey.isCompleted {
            journey.progressCount = min(journey.requiredCompletions, journey.progressCount + 1)
            if journey.progressCount >= journey.requiredCompletions {
                completedJourney = try finishJourney(journey, companion: companion, on: date)
            }
        }

        try save()
        return CompletionResult(
            pebbles: award.pebbles,
            energy: award.energy,
            xp: award.xp,
            leveledUpTo: leveledUpTo,
            journeyCompleted: completedJourney
        )
    }

    /// Undo today's completion of a goal (the toast / tap-again affordance).
    func uncompleteGoal(_ goal: SelfCareGoal, companion: Companion, on date: Date = Date()) throws {
        guard let completion = goal.completions.first(where: { DateUtils.isSameDay($0.date, date) }) else { return }
        // Reverse the currency/energy/xp award.
        companion.pebbles = max(0, companion.pebbles - completion.pebblesAwarded)
        companion.energy = CareEngine.clampEnergy(companion.energy - completion.energyAwarded)
        companion.xp = max(0, companion.xp - completion.energyAwarded)

        // Roll back active journey progress if it advanced today (best-effort, not below 0).
        if let journey = try? activeJourney(), !journey.isCompleted {
            journey.progressCount = max(0, journey.progressCount - 1)
        }
        context.delete(completion)
        try save()
    }

    // MARK: - Journeys

    func activeJourney() throws -> Journey? {
        let descriptor = FetchDescriptor<Journey>(predicate: #Predicate { $0.isActive == true })
        return try context.fetch(descriptor).first
    }

    /// Start a journey: consumes energy, marks active. Only one active at a time.
    func startJourney(_ journey: Journey, companion: Companion, on date: Date = Date()) throws {
        let decayed = CareEngine.decayedEnergy(current: companion.energy, lastTendedAt: companion.lastTendedAt, now: date)
        guard decayed >= journey.energyCost else { throw StoreError.notEnoughEnergy }

        // Deactivate any other active journey (defensive).
        if let other = try activeJourney(), other.persistentModelID != journey.persistentModelID {
            other.isActive = false
        }

        companion.energy = CareEngine.clampEnergy(decayed - journey.energyCost)
        journey.isActive = true
        journey.startedAt = date
        journey.progressCount = 0
        journey.completedAt = nil
        try save()
    }

    func cancelJourney(_ journey: Journey) throws {
        journey.isActive = false
        journey.progressCount = 0
        journey.startedAt = nil
        try save()
    }

    /// Complete a journey, awarding its reward. Does not save (caller saves).
    @discardableResult
    private func finishJourney(_ journey: Journey, companion: Companion, on date: Date) throws -> Journey {
        journey.isActive = false
        journey.completedAt = date
        journey.progressCount = journey.requiredCompletions

        switch journey.rewardKind {
        case .postcard, .cosmetic:
            let postcard = Postcard(
                title: journey.rewardName,
                scene: journey.rewardScene,
                caption: journey.detail,
                earnedAt: date
            )
            context.insert(postcard)
            if journey.rewardKind == .cosmetic, !companion.ownedCosmetics.contains(journey.rewardScene) {
                companion.ownedCosmetics.append(journey.rewardScene)
            }
        case .pebbles:
            companion.pebbles = max(0, companion.pebbles + journey.rewardPebbles)
        }
        return journey
    }

    // MARK: - Check-ins

    /// Insert or update today's check-in (one per day).
    func saveCheckIn(mood: Int, note: String, gratitude: String?, on date: Date = Date()) throws {
        let day = DateUtils.startOfDay(date)
        let descriptor = FetchDescriptor<CheckIn>()
        let existing = (try? context.fetch(descriptor))?.first(where: { DateUtils.isSameDay($0.date, day) })
        if let existing {
            existing.mood = min(5, max(1, mood))
            existing.note = note
            existing.gratitude = (gratitude?.isEmpty ?? true) ? nil : gratitude
        } else {
            let checkIn = CheckIn(date: day, mood: mood, note: note, gratitude: (gratitude?.isEmpty ?? true) ? nil : gratitude)
            context.insert(checkIn)
        }
        try save()
    }

    func deleteCheckIn(_ checkIn: CheckIn) throws {
        context.delete(checkIn)
        try save()
    }

    // MARK: - Goal CRUD

    func deleteGoal(_ goal: SelfCareGoal) throws {
        context.delete(goal)
        try save()
    }

    func persist() throws {
        try save()
    }
}
