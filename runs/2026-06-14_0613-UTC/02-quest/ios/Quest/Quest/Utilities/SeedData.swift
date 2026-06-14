import Foundation
import SwiftData

/// One-time realistic seed so the app feels alive on first launch.
/// Guarded by the `didSeed` UserDefaults flag and re-runnable via Settings → Reset.
enum SeedData {

    /// A compact spec for a seeded game. Sessions are generated from `loggedHours`.
    private struct Spec {
        let title: String
        let platform: Platform
        let genre: Genre
        let status: GameStatus
        let rating: Int
        let storyHours: Double
        let loggedHours: Double
        let favorite: Bool
        /// Months-ago the game was added (rough recency spread).
        let addedMonthsAgo: Int
        /// For completed games: months-ago it was beaten (kept within the spread). nil = not completed.
        let completedMonthsAgo: Int?
    }

    // MARK: Public

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "didSeed") else { return }
        insertAll(context)
        defaults.set(true, forKey: "didSeed")
    }

    /// Wipe all games and re-seed. Used by the Settings reset action.
    @MainActor
    static func resetAndReseed(_ context: ModelContext) {
        do {
            let existing = try context.fetch(FetchDescriptor<Game>())
            for game in existing { context.delete(game) }
        } catch {
            // If the fetch fails we still attempt a fresh seed below.
        }
        insertAll(context)
        try? context.save()
        UserDefaults.standard.set(true, forKey: "didSeed")
    }

    // MARK: Insertion

    @MainActor
    private static func insertAll(_ context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        for spec in specs {
            let added = calendar.date(byAdding: .month, value: -spec.addedMonthsAgo, to: now) ?? now
            var completed: Date? = nil
            if let cm = spec.completedMonthsAgo {
                completed = calendar.date(byAdding: .month, value: -cm, to: now)
            }

            let game = Game(
                title: spec.title,
                platform: spec.platform,
                genre: spec.genre,
                status: spec.status,
                personalRating: spec.rating,
                mainStoryHours: spec.storyHours,
                notes: "",
                dateAdded: added,
                dateCompleted: completed,
                isFavorite: spec.favorite
            )

            // Generate a few play sessions summing roughly to loggedHours,
            // spread across the months between added and now/completed.
            let sessions = makeSessions(for: spec, added: added, completed: completed,
                                        now: now, calendar: calendar)
            context.insert(game)
            for s in sessions {
                context.insert(s)
                game.sessions.append(s)
            }
        }
        try? context.save()
    }

    @MainActor
    private static func makeSessions(for spec: Spec, added: Date, completed: Date?,
                                     now: Date, calendar: Calendar) -> [PlaySession] {
        guard spec.loggedHours > 0 else { return [] }

        let end = completed ?? now
        let span = max(1.0, end.timeIntervalSince(added))
        // 2–5 sessions depending on how much was logged.
        let count = min(5, max(2, Int((spec.loggedHours / 6).rounded()) ))
        var remaining = spec.loggedHours
        var sessions: [PlaySession] = []

        for i in 0..<count {
            let isLast = (i == count - 1)
            let chunk = isLast ? remaining : (spec.loggedHours / Double(count))
            remaining -= chunk
            // Deterministic-ish spread using the title hash so seeds feel natural but stable.
            let frac = Double(i) / Double(max(1, count - 1))
            let offset = span * (0.1 + 0.8 * frac)
            let date = added.addingTimeInterval(offset)
            let safeDate = min(date, end)
            sessions.append(PlaySession(date: safeDate,
                                        hours: max(0.25, chunk),
                                        note: sessionNote(i)))
        }
        return sessions
    }

    private static func sessionNote(_ index: Int) -> String {
        switch index {
        case 0: return "Got started."
        case 1: return "Made real progress."
        case 2: return "Long session."
        default: return ""
        }
    }

    // MARK: The library (52 games — varied platforms, genres, status, ratings, hours)

    private static let specs: [Spec] = [
        // Completed — many this year for the challenge
        Spec(title: "Elden Ring", platform: .playStation, genre: .rpg, status: .completed, rating: 10, storyHours: 58, loggedHours: 72, favorite: true, addedMonthsAgo: 5, completedMonthsAgo: 1),
        Spec(title: "Hades", platform: .nintendoSwitch, genre: .action, status: .completed, rating: 9, storyHours: 22, loggedHours: 31, favorite: true, addedMonthsAgo: 4, completedMonthsAgo: 2),
        Spec(title: "Celeste", platform: .pc, genre: .platformer, status: .completed, rating: 9, storyHours: 8, loggedHours: 11, favorite: true, addedMonthsAgo: 3, completedMonthsAgo: 0),
        Spec(title: "Disco Elysium", platform: .pc, genre: .rpg, status: .completed, rating: 10, storyHours: 30, loggedHours: 34, favorite: true, addedMonthsAgo: 6, completedMonthsAgo: 3),
        Spec(title: "Inside", platform: .xbox, genre: .puzzle, status: .completed, rating: 8, storyHours: 4, loggedHours: 4, favorite: false, addedMonthsAgo: 2, completedMonthsAgo: 1),
        Spec(title: "God of War Ragnarök", platform: .playStation, genre: .action, status: .completed, rating: 9, storyHours: 26, loggedHours: 40, favorite: true, addedMonthsAgo: 4, completedMonthsAgo: 0),
        Spec(title: "Stardew Valley", platform: .nintendoSwitch, genre: .sim, status: .completed, rating: 8, storyHours: 52, loggedHours: 64, favorite: false, addedMonthsAgo: 7, completedMonthsAgo: 4),
        Spec(title: "Portal 2", platform: .pc, genre: .puzzle, status: .completed, rating: 10, storyHours: 9, loggedHours: 10, favorite: true, addedMonthsAgo: 8, completedMonthsAgo: 5),
        Spec(title: "Outer Wilds", platform: .xbox, genre: .adventure, status: .completed, rating: 10, storyHours: 18, loggedHours: 22, favorite: true, addedMonthsAgo: 5, completedMonthsAgo: 2),
        Spec(title: "Tunic", platform: .steamDeck, genre: .adventure, status: .completed, rating: 8, storyHours: 12, loggedHours: 15, favorite: false, addedMonthsAgo: 3, completedMonthsAgo: 1),
        Spec(title: "Vampire Survivors", platform: .mobile, genre: .action, status: .completed, rating: 7, storyHours: 6, loggedHours: 14, favorite: false, addedMonthsAgo: 2, completedMonthsAgo: 0),
        Spec(title: "Metroid Dread", platform: .nintendoSwitch, genre: .platformer, status: .completed, rating: 8, storyHours: 10, loggedHours: 13, favorite: false, addedMonthsAgo: 6, completedMonthsAgo: 3),

        // Currently playing
        Spec(title: "Baldur's Gate 3", platform: .pc, genre: .rpg, status: .playing, rating: 9, storyHours: 75, loggedHours: 41, favorite: true, addedMonthsAgo: 3, completedMonthsAgo: nil),
        Spec(title: "The Legend of Zelda: Tears of the Kingdom", platform: .nintendoSwitch, genre: .adventure, status: .playing, rating: 9, storyHours: 60, loggedHours: 33, favorite: true, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Cyberpunk 2077", platform: .steamDeck, genre: .rpg, status: .playing, rating: 8, storyHours: 24, loggedHours: 17, favorite: false, addedMonthsAgo: 4, completedMonthsAgo: nil),
        Spec(title: "Forza Horizon 5", platform: .xbox, genre: .racing, status: .playing, rating: 8, storyHours: 20, loggedHours: 12, favorite: false, addedMonthsAgo: 1, completedMonthsAgo: nil),

        // Backlog — the heart of the app, varied lengths for pick-next
        Spec(title: "Final Fantasy VII Rebirth", platform: .playStation, genre: .rpg, status: .backlog, rating: 0, storyHours: 80, loggedHours: 0, favorite: true, addedMonthsAgo: 1, completedMonthsAgo: nil),
        Spec(title: "Sekiro: Shadows Die Twice", platform: .pc, genre: .action, status: .backlog, rating: 0, storyHours: 30, loggedHours: 0, favorite: false, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Hollow Knight", platform: .steamDeck, genre: .platformer, status: .backlog, rating: 0, storyHours: 27, loggedHours: 2, favorite: true, addedMonthsAgo: 3, completedMonthsAgo: nil),
        Spec(title: "Pentiment", platform: .xbox, genre: .adventure, status: .backlog, rating: 0, storyHours: 16, loggedHours: 0, favorite: false, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Cuphead", platform: .nintendoSwitch, genre: .platformer, status: .backlog, rating: 0, storyHours: 12, loggedHours: 0, favorite: false, addedMonthsAgo: 4, completedMonthsAgo: nil),
        Spec(title: "Death Stranding", platform: .pc, genre: .adventure, status: .backlog, rating: 0, storyHours: 40, loggedHours: 0, favorite: false, addedMonthsAgo: 5, completedMonthsAgo: nil),
        Spec(title: "Slay the Spire", platform: .mobile, genre: .strategy, status: .backlog, rating: 0, storyHours: 8, loggedHours: 0, favorite: true, addedMonthsAgo: 1, completedMonthsAgo: nil),
        Spec(title: "Resident Evil 4", platform: .playStation, genre: .horror, status: .backlog, rating: 0, storyHours: 16, loggedHours: 0, favorite: false, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Dave the Diver", platform: .steamDeck, genre: .sim, status: .backlog, rating: 0, storyHours: 22, loggedHours: 0, favorite: false, addedMonthsAgo: 1, completedMonthsAgo: nil),
        Spec(title: "Pizza Tower", platform: .pc, genre: .platformer, status: .backlog, rating: 0, storyHours: 9, loggedHours: 0, favorite: false, addedMonthsAgo: 3, completedMonthsAgo: nil),
        Spec(title: "Octopath Traveler II", platform: .nintendoSwitch, genre: .rpg, status: .backlog, rating: 0, storyHours: 58, loggedHours: 0, favorite: false, addedMonthsAgo: 4, completedMonthsAgo: nil),
        Spec(title: "Dead Cells", platform: .mobile, genre: .action, status: .backlog, rating: 0, storyHours: 11, loggedHours: 0, favorite: false, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Return of the Obra Dinn", platform: .pc, genre: .puzzle, status: .backlog, rating: 0, storyHours: 8, loggedHours: 0, favorite: true, addedMonthsAgo: 5, completedMonthsAgo: nil),
        Spec(title: "Yakuza: Like a Dragon", platform: .xbox, genre: .rpg, status: .backlog, rating: 0, storyHours: 45, loggedHours: 0, favorite: false, addedMonthsAgo: 6, completedMonthsAgo: nil),
        Spec(title: "Gran Turismo 7", platform: .playStation, genre: .racing, status: .backlog, rating: 0, storyHours: 30, loggedHours: 0, favorite: false, addedMonthsAgo: 3, completedMonthsAgo: nil),
        Spec(title: "Street Fighter 6", platform: .playStation, genre: .fighting, status: .backlog, rating: 0, storyHours: 14, loggedHours: 0, favorite: false, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Tetris Effect", platform: .pc, genre: .puzzle, status: .backlog, rating: 0, storyHours: 6, loggedHours: 0, favorite: false, addedMonthsAgo: 4, completedMonthsAgo: nil),
        Spec(title: "Spiritfarer", platform: .nintendoSwitch, genre: .indie, status: .backlog, rating: 0, storyHours: 25, loggedHours: 0, favorite: false, addedMonthsAgo: 5, completedMonthsAgo: nil),
        Spec(title: "Doom Eternal", platform: .pc, genre: .shooter, status: .backlog, rating: 0, storyHours: 15, loggedHours: 0, favorite: false, addedMonthsAgo: 1, completedMonthsAgo: nil),
        Spec(title: "Civilization VI", platform: .pc, genre: .strategy, status: .backlog, rating: 0, storyHours: 40, loggedHours: 0, favorite: false, addedMonthsAgo: 7, completedMonthsAgo: nil),
        Spec(title: "A Short Hike", platform: .steamDeck, genre: .indie, status: .backlog, rating: 0, storyHours: 3, loggedHours: 0, favorite: true, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Sifu", platform: .playStation, genre: .fighting, status: .backlog, rating: 0, storyHours: 10, loggedHours: 0, favorite: false, addedMonthsAgo: 3, completedMonthsAgo: nil),
        Spec(title: "Chrono Trigger", platform: .retro, genre: .rpg, status: .backlog, rating: 0, storyHours: 22, loggedHours: 0, favorite: true, addedMonthsAgo: 8, completedMonthsAgo: nil),
        Spec(title: "Super Metroid", platform: .retro, genre: .platformer, status: .backlog, rating: 0, storyHours: 9, loggedHours: 0, favorite: false, addedMonthsAgo: 9, completedMonthsAgo: nil),

        // Abandoned
        Spec(title: "No Man's Sky", platform: .pc, genre: .adventure, status: .abandoned, rating: 5, storyHours: 30, loggedHours: 9, favorite: false, addedMonthsAgo: 10, completedMonthsAgo: nil),
        Spec(title: "Assassin's Creed Valhalla", platform: .xbox, genre: .action, status: .abandoned, rating: 6, storyHours: 60, loggedHours: 18, favorite: false, addedMonthsAgo: 9, completedMonthsAgo: nil),
        Spec(title: "Anthem", platform: .playStation, genre: .shooter, status: .abandoned, rating: 4, storyHours: 20, loggedHours: 6, favorite: false, addedMonthsAgo: 11, completedMonthsAgo: nil),
        Spec(title: "Final Fantasy XIV", platform: .pc, genre: .mmo, status: .abandoned, rating: 7, storyHours: 100, loggedHours: 24, favorite: false, addedMonthsAgo: 12, completedMonthsAgo: nil),

        // Wishlist
        Spec(title: "Silksong", platform: .steamDeck, genre: .platformer, status: .wishlist, rating: 0, storyHours: 0, loggedHours: 0, favorite: true, addedMonthsAgo: 1, completedMonthsAgo: nil),
        Spec(title: "Metroid Prime 4", platform: .nintendoSwitch, genre: .shooter, status: .wishlist, rating: 0, storyHours: 0, loggedHours: 0, favorite: false, addedMonthsAgo: 1, completedMonthsAgo: nil),
        Spec(title: "Ghost of Yotei", platform: .playStation, genre: .action, status: .wishlist, rating: 0, storyHours: 0, loggedHours: 0, favorite: false, addedMonthsAgo: 1, completedMonthsAgo: nil),
        Spec(title: "Hades II", platform: .pc, genre: .action, status: .wishlist, rating: 0, storyHours: 0, loggedHours: 0, favorite: true, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Monster Hunter Wilds", platform: .xbox, genre: .rpg, status: .wishlist, rating: 0, storyHours: 0, loggedHours: 0, favorite: false, addedMonthsAgo: 2, completedMonthsAgo: nil),
        Spec(title: "Pokémon Legends: Z-A", platform: .nintendoSwitch, genre: .rpg, status: .wishlist, rating: 0, storyHours: 0, loggedHours: 0, favorite: false, addedMonthsAgo: 1, completedMonthsAgo: nil),

        // A couple more completed in earlier months to spread monthly stats
        Spec(title: "It Takes Two", platform: .playStation, genre: .platformer, status: .completed, rating: 9, storyHours: 14, loggedHours: 16, favorite: false, addedMonthsAgo: 9, completedMonthsAgo: 6),
        Spec(title: "Ori and the Will of the Wisps", platform: .xbox, genre: .platformer, status: .completed, rating: 9, storyHours: 12, loggedHours: 14, favorite: true, addedMonthsAgo: 10, completedMonthsAgo: 7),
        Spec(title: "Hi-Fi Rush", platform: .pc, genre: .action, status: .completed, rating: 8, storyHours: 12, loggedHours: 13, favorite: false, addedMonthsAgo: 8, completedMonthsAgo: 5),
    ]
}
