import Foundation
import SwiftData

/// Seeds a believable starter library on first launch so every screen — the
/// list, stats charts and the shuffle picker — is alive immediately.
enum SeedData {
    @MainActor
    static func installIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Game>())) ?? 0
        guard count == 0 else { return }

        struct Spec {
            let title: String; let platform: Platform; let genre: Genre
            let status: GameStatus; let priority: Priority
            let rating: Int; let played: Double; let est: Double; let price: Double
        }

        let specs: [Spec] = [
            .init(title: "Elden Ring", platform: .ps5, genre: .rpg, status: .playing, priority: .high, rating: 9, played: 42, est: 58, price: 59.99),
            .init(title: "Hades", platform: .switchC, genre: .indie, status: .completed, priority: .medium, rating: 10, played: 64, est: 22, price: 24.99),
            .init(title: "Baldur's Gate 3", platform: .pc, genre: .rpg, status: .playing, priority: .next, rating: 9, played: 28, est: 75, price: 59.99),
            .init(title: "Stardew Valley", platform: .mobile, genre: .sim, status: .playing, priority: .low, rating: 9, played: 110, est: 52, price: 4.99),
            .init(title: "Celeste", platform: .switchC, genre: .platformer, status: .beaten, priority: .medium, rating: 9, played: 12, est: 8, price: 19.99),
            .init(title: "Disco Elysium", platform: .pc, genre: .rpg, status: .backlog, priority: .high, rating: 0, played: 0, est: 26, price: 39.99),
            .init(title: "Hollow Knight", platform: .steamDeck, genre: .platformer, status: .backlog, priority: .high, rating: 0, played: 3, est: 27, price: 14.99),
            .init(title: "Cyberpunk 2077", platform: .ps5, genre: .rpg, status: .backlog, priority: .medium, rating: 0, played: 0, est: 24, price: 29.99),
            .init(title: "Tunic", platform: .xbox, genre: .adventure, status: .backlog, priority: .medium, rating: 0, played: 0, est: 12, price: 29.99),
            .init(title: "Outer Wilds", platform: .pc, genre: .adventure, status: .backlog, priority: .next, rating: 0, played: 0, est: 15, price: 24.99),
            .init(title: "Returnal", platform: .ps5, genre: .shooter, status: .abandoned, priority: .someday, rating: 6, played: 9, est: 19, price: 69.99),
            .init(title: "Vampire Survivors", platform: .mobile, genre: .action, status: .beaten, priority: .low, rating: 8, played: 18, est: 7, price: 4.99),
            .init(title: "Pentiment", platform: .pc, genre: .adventure, status: .completed, priority: .medium, rating: 9, played: 20, est: 18, price: 19.99),
            .init(title: "Sea of Stars", platform: .switchC, genre: .rpg, status: .backlog, priority: .low, rating: 0, played: 0, est: 30, price: 34.99),
            .init(title: "Lies of P", platform: .ps5, genre: .action, status: .wishlist, priority: .someday, rating: 0, played: 0, est: 32, price: 59.99),
            .init(title: "Pizza Tower", platform: .pc, genre: .platformer, status: .wishlist, priority: .someday, rating: 0, played: 0, est: 9, price: 19.99),
            .init(title: "Cocoon", platform: .switchC, genre: .puzzle, status: .backlog, priority: .medium, rating: 0, played: 0, est: 5, price: 24.99),
            .init(title: "Dave the Diver", platform: .steamDeck, genre: .indie, status: .beaten, priority: .low, rating: 8, played: 24, est: 18, price: 19.99),
        ]

        let cal = Calendar.current
        for (i, s) in specs.enumerated() {
            let g = Game(title: s.title, platform: s.platform, genre: s.genre, status: s.status,
                         priority: s.priority, ratingHalf: s.rating, hoursPlayed: s.played,
                         estimatedHours: s.est, pricePaid: s.price)
            g.dateAdded = cal.date(byAdding: .day, value: -(i * 11 + 4), to: Date()) ?? Date()
            if s.played > 0 { g.dateStarted = cal.date(byAdding: .day, value: -(i * 9 + 2), to: Date()) }
            if s.status.isFinished { g.dateFinished = cal.date(byAdding: .day, value: -(i * 5 + 1), to: Date()) }
            context.insert(g)
            // A couple of sessions for the actively-played titles.
            if s.played > 0 {
                let chunks = min(4, max(1, Int(s.played / 12)))
                for c in 0..<chunks {
                    let sess = PlaySession(date: cal.date(byAdding: .day, value: -(c * 6 + 1), to: Date()) ?? Date(),
                                           hours: s.played / Double(chunks),
                                           note: c == 0 ? "Latest run" : "")
                    sess.game = g
                    g.sessions.append(sess)
                }
            }
        }
        try? context.save()
    }
}
