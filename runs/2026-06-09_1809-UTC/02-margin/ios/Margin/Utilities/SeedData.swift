import Foundation
import SwiftData

/// Seeds a realistic starter library on first launch so every screen — shelf,
/// library, challenge ring, and Charts — has meaningful content for a brand-new
/// user. Guarded so it runs at most once.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Book>())) ?? []
        guard existing.isEmpty else { return }

        var rng = SeededGenerator(seed: 0x4D4152_47494E)   // "MARGIN"
        let cal = Calendar.current
        let now = Date.now
        let year = cal.component(.year, from: now)
        let yearStart = cal.date(from: DateComponents(year: year, month: 1, day: 1)) ?? now

        // MARK: Tags
        let tagSpec: [(String, UInt32)] = [
            ("Cozy", 0xB07A4C),
            ("Page-turner", 0xC0553E),
            ("Book club", 0x4E6BA8),
            ("Comfort read", 0x3E9E78),
            ("Heavy", 0x6B5B95),
            ("Reread", 0xC08A3E)
        ]
        let tags: [BookTag] = tagSpec.map { BookTag(name: $0.0, colorHex: String(format: "%06X", $0.1)) }
        tags.forEach { context.insert($0) }

        // MARK: Book catalog (title, author, pages, genre)
        let catalog: [(String, String, Int, BookGenre)] = [
            ("The Salt Path", "Raynor Winn", 288, .nonfiction),
            ("Project Hail Mary", "Andy Weir", 496, .sciFi),
            ("Klara and the Sun", "Kazuo Ishiguro", 320, .fiction),
            ("The Midnight Library", "Matt Haig", 304, .fiction),
            ("Piranesi", "Susanna Clarke", 272, .fantasy),
            ("Educated", "Tara Westover", 352, .biography),
            ("The Thursday Murder Club", "Richard Osman", 400, .mystery),
            ("Tomorrow, and Tomorrow, and Tomorrow", "Gabrielle Zevin", 416, .fiction),
            ("Babel", "R. F. Kuang", 560, .fantasy),
            ("The Silent Patient", "Alex Michaelides", 336, .thriller),
            ("Atomic Habits", "James Clear", 320, .selfHelp),
            ("A Little Life", "Hanya Yanagihara", 720, .fiction),
            ("Circe", "Madeline Miller", 416, .fantasy),
            ("The Song of Achilles", "Madeline Miller", 384, .fantasy),
            ("Lessons in Chemistry", "Bonnie Garmus", 400, .fiction),
            ("Sapiens", "Yuval Noah Harari", 512, .history),
            ("The Goldfinch", "Donna Tartt", 784, .fiction),
            ("Normal People", "Sally Rooney", 288, .fiction),
            ("The Seven Husbands of Evelyn Hugo", "Taylor Jenkins Reid", 400, .romance),
            ("Dune", "Frank Herbert", 688, .sciFi),
            ("The Name of the Wind", "Patrick Rothfuss", 662, .fantasy),
            ("Where the Crawdads Sing", "Delia Owens", 384, .fiction),
            ("Gone Girl", "Gillian Flynn", 432, .thriller),
            ("The Body Keeps the Score", "Bessel van der Kolk", 464, .nonfiction),
            ("Verity", "Colleen Hoover", 336, .thriller),
            ("Crying in H Mart", "Michelle Zauner", 256, .biography),
            ("The House in the Cerulean Sea", "TJ Klune", 396, .fantasy),
            ("Cloud Cuckoo Land", "Anthony Doerr", 640, .fiction),
            ("The Vanishing Half", "Brit Bennett", 352, .fiction),
            ("Hamnet", "Maggie O'Farrell", 384, .history),
            ("Mexican Gothic", "Silvia Moreno-Garcia", 320, .mystery),
            ("Beach Read", "Emily Henry", 368, .romance),
            ("The Lincoln Highway", "Amor Towles", 592, .fiction),
            ("Devotions", "Mary Oliver", 480, .poetry),
            ("Four Thousand Weeks", "Oliver Burkeman", 288, .selfHelp),
            ("Demon Copperhead", "Barbara Kingsolver", 560, .fiction),
            ("The Power", "Naomi Alderman", 400, .sciFi),
            ("Anxious People", "Fredrik Backman", 352, .fiction),
            ("Carrie Soto Is Back", "Taylor Jenkins Reid", 384, .fiction),
            ("The Invisible Life of Addie LaRue", "V. E. Schwab", 448, .fantasy)
        ]

        let formats: [BookFormat] = [.paper, .paper, .ebook, .audio]

        // We want a chunk finished across this year's months, several reading
        // with sessions, and some on the want-to-read shelf.
        // Indices 0..<24 finished, 24..<32 reading, 32..< wantToRead.
        for (i, entry) in catalog.enumerated() {
            let (title, author, pages, genre) = entry
            let format = formats.randomElement(using: &rng) ?? .paper

            let book: Book
            if i < 24 {
                // Finished earlier this year, spread across months up to "now".
                let monthsBack = Int(rng.next() % 6)            // 0…5 months ago
                let finishBase = cal.date(byAdding: .month, value: -monthsBack, to: now) ?? now
                // clamp finish into this year
                let finishedAt = max(yearStart, min(finishBase, now))
                let readingDays = 6 + Int(rng.next() % 40)      // 6…45 days
                let startedAt = cal.date(byAdding: .day, value: -readingDays, to: finishedAt) ?? finishedAt
                let rating = 3 + Int(rng.next() % 3)            // 3…5
                book = Book(title: title, author: author, totalPages: pages,
                            currentPage: pages, genre: genre, status: .finished,
                            rating: rating, format: format,
                            startedAt: startedAt, finishedAt: finishedAt,
                            addedAt: cal.date(byAdding: .day, value: -3, to: startedAt) ?? startedAt)
                context.insert(book)
                attach(tags: tags, to: book, rng: &rng)
                // A few sessions during the reading window.
                seedSessions(context, book: book, from: startedAt, to: finishedAt,
                             totalPages: pages, rng: &rng)
            } else if i < 32 {
                // Currently reading with partial progress + recent sessions.
                let startedDaysAgo = 4 + Int(rng.next() % 24)   // 4…27 days ago
                let startedAt = cal.date(byAdding: .day, value: -startedDaysAgo, to: now) ?? now
                let progressPages = max(20, Int(Double(pages) * (0.2 + Double(rng.next() % 50) / 100.0)))
                let current = min(progressPages, pages - 10)
                book = Book(title: title, author: author, totalPages: pages,
                            currentPage: current, genre: genre, status: .reading,
                            rating: 0, format: format,
                            startedAt: startedAt, finishedAt: nil,
                            addedAt: cal.date(byAdding: .day, value: -2, to: startedAt) ?? startedAt)
                context.insert(book)
                attach(tags: tags, to: book, rng: &rng)
                seedSessions(context, book: book, from: startedAt, to: now,
                             totalPages: current, rng: &rng)
            } else {
                // Want-to-read shelf.
                book = Book(title: title, author: author, totalPages: pages,
                            currentPage: 0, genre: genre, status: .wantToRead,
                            rating: 0, format: format,
                            startedAt: nil, finishedAt: nil,
                            addedAt: cal.date(byAdding: .day, value: -Int(rng.next() % 60), to: now) ?? now)
                context.insert(book)
                if rng.next() % 2 == 0 { attach(tags: tags, to: book, rng: &rng) }
            }
        }

        try? context.save()
    }

    /// Attaches 0–2 random tags to a book.
    private static func attach(tags: [BookTag], to book: Book, rng: inout SeededGenerator) {
        guard !tags.isEmpty else { return }
        let count = Int(rng.next() % 3)   // 0…2
        var chosen = Set<Int>()
        for _ in 0..<count { chosen.insert(Int(rng.next() % UInt64(tags.count))) }
        book.tags = chosen.compactMap { tags.indices.contains($0) ? tags[$0] : nil }
    }

    /// Creates a handful of sessions whose pages roughly sum to `totalPages`.
    private static func seedSessions(_ context: ModelContext,
                                     book: Book,
                                     from start: Date,
                                     to end: Date,
                                     totalPages: Int,
                                     rng: inout SeededGenerator) {
        guard totalPages > 0, end >= start else { return }
        let cal = Calendar.current
        let span = max(1, cal.dateComponents([.day], from: start, to: end).day ?? 1)
        let sessionCount = max(2, min(8, span / 3 + 2))
        var remaining = totalPages
        for s in 0..<sessionCount {
            let dayOffset = (span * s) / sessionCount + Int(rng.next() % 2)
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: start) else { continue }
            if date > end { continue }
            let isLast = s == sessionCount - 1
            let pages: Int
            if isLast {
                pages = max(0, remaining)
            } else {
                let chunk = max(8, totalPages / sessionCount + Int(rng.next() % 25) - 10)
                pages = min(remaining, chunk)
            }
            remaining = max(0, remaining - pages)
            let minutes = max(10, pages * (1 + Int(rng.next() % 2)))
            let session = ReadingSession(date: date, pagesRead: pages, minutes: minutes)
            session.book = book
            context.insert(session)
        }
    }
}

/// A tiny deterministic PRNG (SplitMix64) so seeded content is identical across
/// launches and never depends on system randomness.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
