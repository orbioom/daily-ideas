import Foundation
import SwiftData

/// Seeds a rich sample life on first run so the grid, lists, and stats are full immediately.
/// A person born mid-1995, expectancy 90, with six chapters, several milestones, and a few
/// future goals. Gated behind the `didSeed` flag.
enum SeedData {

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = 12
        let cal = Calendar(identifier: .gregorian)
        return cal.date(from: c) ?? Date(timeIntervalSince1970: 0)
    }

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        // Only seed if there's no profile yet (respect a user who set up via onboarding).
        let existing = (try? context.fetch(FetchDescriptor<LifeProfile>())) ?? []
        if existing.isEmpty {
            insertSampleLife(context: context)
        }
        didSeed = true
    }

    /// Insert a fresh sample life. Clears any existing sample data first when reloaded.
    static func insertSampleLife(context: ModelContext) {
        let birth = date(1995, 6, 21)

        let profile = LifeProfile(name: "You",
                                  birthDate: birth,
                                  lifeExpectancyYears: 90,
                                  weekStartsMonday: true)
        context.insert(profile)

        let p = Palettes.classic
        let chapters: [Chapter] = [
            Chapter(title: "Childhood", startDate: date(1995, 6, 21), endDate: date(2007, 9, 1),
                    colorHex: p.hexes[1], note: "Backyards, summers, and learning to read.", sortOrder: 0),
            Chapter(title: "School", startDate: date(2007, 9, 1), endDate: date(2013, 6, 15),
                    colorHex: p.hexes[2], note: "Friendships, exams, first heartbreaks.", sortOrder: 1),
            Chapter(title: "University", startDate: date(2013, 9, 1), endDate: date(2017, 6, 1),
                    colorHex: p.hexes[3], note: "A new city and a head full of ideas.", sortOrder: 2),
            Chapter(title: "First Job", startDate: date(2017, 7, 1), endDate: date(2020, 3, 1),
                    colorHex: p.hexes[4], note: "Learning what work really means.", sortOrder: 3),
            Chapter(title: "Lisbon Years", startDate: date(2020, 3, 1), endDate: date(2024, 1, 1),
                    colorHex: p.hexes[0], note: "Tiled streets, the ocean, slow mornings.", sortOrder: 4),
            Chapter(title: "Present", startDate: date(2024, 1, 1), endDate: nil,
                    colorHex: p.hexes[5], note: "Where the story is being written now.", sortOrder: 5)
        ]
        for c in chapters { context.insert(c) }

        let milestones: [LifeMilestone] = [
            LifeMilestone(title: "First day of school", date: date(2000, 9, 4),
                          symbolName: "backpack.fill", colorHex: p.hexes[1]),
            LifeMilestone(title: "Learned to ride a bike", date: date(2002, 7, 12),
                          symbolName: "bicycle", colorHex: p.hexes[2]),
            LifeMilestone(title: "Graduated university", date: date(2017, 6, 1),
                          symbolName: "graduationcap.fill", colorHex: p.hexes[3],
                          note: "Threw the cap. Felt unstoppable."),
            LifeMilestone(title: "Moved to Lisbon", date: date(2020, 3, 14),
                          symbolName: "airplane", colorHex: p.hexes[0]),
            LifeMilestone(title: "Ran a marathon", date: date(2022, 10, 9),
                          symbolName: "figure.run", colorHex: p.hexes[4],
                          note: "26.2 miles, and a different person at the end.")
        ]
        for m in milestones { context.insert(m) }

        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let goals: [FutureGoal] = [
            FutureGoal(title: "Sabbatical year",
                       targetDate: cal.date(byAdding: .day, value: 220, to: now) ?? now,
                       note: "Twelve months to wander.", colorHex: p.hexes[0]),
            FutureGoal(title: "Visit all 7 continents",
                       targetDate: cal.date(byAdding: .day, value: 900, to: now) ?? now,
                       note: "Antarctica is the last one.", colorHex: p.hexes[1]),
            FutureGoal(title: "Turn 40",
                       targetDate: date(2035, 6, 21),
                       note: "A whole new decade.", colorHex: p.hexes[3])
        ]
        for g in goals { context.insert(g) }

        try? context.save()
    }

    /// Seed a few chapters, milestones, and goals scaled to a real user's birth date, so the
    /// grid and lists aren't empty after onboarding. Approximate eras based on typical ages.
    static func insertSampleChaptersAndMoments(context: ModelContext, for profile: LifeProfile) {
        let cal = Calendar(identifier: .gregorian)
        let birth = profile.birthDate
        func age(_ years: Int, _ months: Int = 0) -> Date {
            var c = DateComponents(); c.year = years; c.month = months
            return cal.date(byAdding: c, to: birth) ?? birth
        }
        let now = Date()
        let p = Palettes.classic

        let childEnd = min(age(12), now)
        let schoolEnd = min(age(18), now)
        let presentStart = min(age(18), now)

        var chapters: [Chapter] = [
            Chapter(title: "Childhood", startDate: birth, endDate: childEnd,
                    colorHex: p.hexes[1], note: "Where it all began.", sortOrder: 0),
            Chapter(title: "School Years", startDate: childEnd, endDate: schoolEnd,
                    colorHex: p.hexes[2], note: nil, sortOrder: 1)
        ]
        // Only add a "Present" chapter if the person is at least 18.
        if presentStart < now {
            chapters.append(Chapter(title: "Present", startDate: presentStart, endDate: nil,
                                    colorHex: p.hexes[5], note: "The chapter you're living now.",
                                    sortOrder: 2))
        }
        for c in chapters { context.insert(c) }

        let milestones: [LifeMilestone] = [
            LifeMilestone(title: "Born", date: birth,
                          symbolName: "sparkles", colorHex: p.hexes[0])
        ]
        for m in milestones { context.insert(m) }

        let goals: [FutureGoal] = [
            FutureGoal(title: "Next birthday",
                       targetDate: nextBirthday(of: birth, after: now),
                       note: "Another trip around the sun.", colorHex: p.hexes[0])
        ]
        for g in goals { context.insert(g) }
    }

    private static func nextBirthday(of birth: Date, after now: Date) -> Date {
        let cal = Calendar(identifier: .gregorian)
        let bComps = cal.dateComponents([.month, .day], from: birth)
        var next = cal.nextDate(after: now,
                                matching: DateComponents(month: bComps.month, day: bComps.day),
                                matchingPolicy: .nextTimePreservingSmallerComponents)
        if next == nil {
            next = cal.date(byAdding: .year, value: 1, to: now)
        }
        return next ?? cal.date(byAdding: .year, value: 1, to: now) ?? now
    }

    // MARK: - Bulk operations

    static func clearAll(context: ModelContext) {
        delete(LifeProfile.self, context: context)
        delete(Chapter.self, context: context)
        delete(LifeMilestone.self, context: context)
        delete(FutureGoal.self, context: context)
        try? context.save()
    }

    static func reloadSample(context: ModelContext) {
        clearAll(context: context)
        insertSampleLife(context: context)
    }

    private static func delete<T: PersistentModel>(_ type: T.Type, context: ModelContext) {
        if let items = try? context.fetch(FetchDescriptor<T>()) {
            for item in items { context.delete(item) }
        }
    }
}
