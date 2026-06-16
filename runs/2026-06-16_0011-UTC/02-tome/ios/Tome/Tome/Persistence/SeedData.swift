import Foundation
import SwiftData

/// Seeds a realistic 50+ book library with sessions, ratings, reviews, and tags.
enum SeedData {

    private struct Entry {
        let title: String
        let author: String
        let pages: Int
        let genre: String
        let series: String
        let seriesNo: Int
    }

    /// Public facts: title / author / page count / genre. 56 books across genres.
    private static let catalog: [Entry] = [
        Entry(title: "Dune", author: "Frank Herbert", pages: 688, genre: "Sci-Fi", series: "Dune", seriesNo: 1),
        Entry(title: "Dune Messiah", author: "Frank Herbert", pages: 256, genre: "Sci-Fi", series: "Dune", seriesNo: 2),
        Entry(title: "The Left Hand of Darkness", author: "Ursula K. Le Guin", pages: 304, genre: "Sci-Fi", series: "", seriesNo: 0),
        Entry(title: "Project Hail Mary", author: "Andy Weir", pages: 496, genre: "Sci-Fi", series: "", seriesNo: 0),
        Entry(title: "The Martian", author: "Andy Weir", pages: 384, genre: "Sci-Fi", series: "", seriesNo: 0),
        Entry(title: "Neuromancer", author: "William Gibson", pages: 271, genre: "Sci-Fi", series: "Sprawl", seriesNo: 1),
        Entry(title: "Hyperion", author: "Dan Simmons", pages: 482, genre: "Sci-Fi", series: "Hyperion Cantos", seriesNo: 1),
        Entry(title: "Foundation", author: "Isaac Asimov", pages: 244, genre: "Sci-Fi", series: "Foundation", seriesNo: 1),
        Entry(title: "The Name of the Wind", author: "Patrick Rothfuss", pages: 662, genre: "Fantasy", series: "Kingkiller", seriesNo: 1),
        Entry(title: "The Wise Man's Fear", author: "Patrick Rothfuss", pages: 994, genre: "Fantasy", series: "Kingkiller", seriesNo: 2),
        Entry(title: "The Hobbit", author: "J.R.R. Tolkien", pages: 310, genre: "Fantasy", series: "Middle-earth", seriesNo: 0),
        Entry(title: "The Fellowship of the Ring", author: "J.R.R. Tolkien", pages: 423, genre: "Fantasy", series: "The Lord of the Rings", seriesNo: 1),
        Entry(title: "A Game of Thrones", author: "George R.R. Martin", pages: 694, genre: "Fantasy", series: "A Song of Ice and Fire", seriesNo: 1),
        Entry(title: "Mistborn: The Final Empire", author: "Brandon Sanderson", pages: 541, genre: "Fantasy", series: "Mistborn", seriesNo: 1),
        Entry(title: "The Way of Kings", author: "Brandon Sanderson", pages: 1007, genre: "Fantasy", series: "The Stormlight Archive", seriesNo: 1),
        Entry(title: "The Lies of Locke Lamora", author: "Scott Lynch", pages: 499, genre: "Fantasy", series: "Gentleman Bastard", seriesNo: 1),
        Entry(title: "A Wizard of Earthsea", author: "Ursula K. Le Guin", pages: 183, genre: "Fantasy", series: "Earthsea", seriesNo: 1),
        Entry(title: "Piranesi", author: "Susanna Clarke", pages: 245, genre: "Fantasy", series: "", seriesNo: 0),
        Entry(title: "Pride and Prejudice", author: "Jane Austen", pages: 432, genre: "Classics", series: "", seriesNo: 0),
        Entry(title: "Jane Eyre", author: "Charlotte Brontë", pages: 532, genre: "Classics", series: "", seriesNo: 0),
        Entry(title: "Wuthering Heights", author: "Emily Brontë", pages: 416, genre: "Classics", series: "", seriesNo: 0),
        Entry(title: "Crime and Punishment", author: "Fyodor Dostoevsky", pages: 671, genre: "Classics", series: "", seriesNo: 0),
        Entry(title: "The Great Gatsby", author: "F. Scott Fitzgerald", pages: 180, genre: "Classics", series: "", seriesNo: 0),
        Entry(title: "1984", author: "George Orwell", pages: 328, genre: "Classics", series: "", seriesNo: 0),
        Entry(title: "Brave New World", author: "Aldous Huxley", pages: 311, genre: "Classics", series: "", seriesNo: 0),
        Entry(title: "Mrs Dalloway", author: "Virginia Woolf", pages: 194, genre: "Classics", series: "", seriesNo: 0),
        Entry(title: "Beloved", author: "Toni Morrison", pages: 324, genre: "Literary", series: "", seriesNo: 0),
        Entry(title: "Normal People", author: "Sally Rooney", pages: 273, genre: "Literary", series: "", seriesNo: 0),
        Entry(title: "A Little Life", author: "Hanya Yanagihara", pages: 720, genre: "Literary", series: "", seriesNo: 0),
        Entry(title: "The Secret History", author: "Donna Tartt", pages: 559, genre: "Literary", series: "", seriesNo: 0),
        Entry(title: "Klara and the Sun", author: "Kazuo Ishiguro", pages: 303, genre: "Literary", series: "", seriesNo: 0),
        Entry(title: "Never Let Me Go", author: "Kazuo Ishiguro", pages: 288, genre: "Literary", series: "", seriesNo: 0),
        Entry(title: "The Overstory", author: "Richard Powers", pages: 502, genre: "Literary", series: "", seriesNo: 0),
        Entry(title: "Tomorrow, and Tomorrow, and Tomorrow", author: "Gabrielle Zevin", pages: 416, genre: "Literary", series: "", seriesNo: 0),
        Entry(title: "Gone Girl", author: "Gillian Flynn", pages: 432, genre: "Thriller", series: "", seriesNo: 0),
        Entry(title: "The Silent Patient", author: "Alex Michaelides", pages: 336, genre: "Thriller", series: "", seriesNo: 0),
        Entry(title: "The Girl with the Dragon Tattoo", author: "Stieg Larsson", pages: 672, genre: "Thriller", series: "Millennium", seriesNo: 1),
        Entry(title: "The Da Vinci Code", author: "Dan Brown", pages: 489, genre: "Thriller", series: "Robert Langdon", seriesNo: 2),
        Entry(title: "And Then There Were None", author: "Agatha Christie", pages: 272, genre: "Mystery", series: "", seriesNo: 0),
        Entry(title: "The Thursday Murder Club", author: "Richard Osman", pages: 382, genre: "Mystery", series: "Thursday Murder Club", seriesNo: 1),
        Entry(title: "Sapiens", author: "Yuval Noah Harari", pages: 443, genre: "Nonfiction", series: "", seriesNo: 0),
        Entry(title: "Educated", author: "Tara Westover", pages: 334, genre: "Memoir", series: "", seriesNo: 0),
        Entry(title: "Atomic Habits", author: "James Clear", pages: 320, genre: "Nonfiction", series: "", seriesNo: 0),
        Entry(title: "Thinking, Fast and Slow", author: "Daniel Kahneman", pages: 499, genre: "Nonfiction", series: "", seriesNo: 0),
        Entry(title: "The Body Keeps the Score", author: "Bessel van der Kolk", pages: 464, genre: "Nonfiction", series: "", seriesNo: 0),
        Entry(title: "Born a Crime", author: "Trevor Noah", pages: 304, genre: "Memoir", series: "", seriesNo: 0),
        Entry(title: "Braiding Sweetgrass", author: "Robin Wall Kimmerer", pages: 391, genre: "Nonfiction", series: "", seriesNo: 0),
        Entry(title: "The Song of Achilles", author: "Madeline Miller", pages: 416, genre: "Historical", series: "", seriesNo: 0),
        Entry(title: "Circe", author: "Madeline Miller", pages: 393, genre: "Historical", series: "", seriesNo: 0),
        Entry(title: "All the Light We Cannot See", author: "Anthony Doerr", pages: 531, genre: "Historical", series: "", seriesNo: 0),
        Entry(title: "The Book Thief", author: "Markus Zusak", pages: 552, genre: "Historical", series: "", seriesNo: 0),
        Entry(title: "Pachinko", author: "Min Jin Lee", pages: 490, genre: "Historical", series: "", seriesNo: 0),
        Entry(title: "Beach Read", author: "Emily Henry", pages: 361, genre: "Romance", series: "", seriesNo: 0),
        Entry(title: "The Seven Husbands of Evelyn Hugo", author: "Taylor Jenkins Reid", pages: 389, genre: "Romance", series: "", seriesNo: 0),
        Entry(title: "Red, White & Royal Blue", author: "Casey McQuiston", pages: 421, genre: "Romance", series: "", seriesNo: 0),
        Entry(title: "The House in the Cerulean Sea", author: "TJ Klune", pages: 396, genre: "Fantasy", series: "", seriesNo: 0)
    ]

    /// Reviews paired by index for some finished books.
    private static let sampleReviews: [String] = [
        "A towering achievement. The world-building never lets up.",
        "Slow to start, but the back half is unforgettable.",
        "Comfort read of the year — I'll be rereading this.",
        "Beautifully written, even if the pacing wandered.",
        "Couldn't put it down. Stayed up far too late.",
        "Quietly devastating in the best way.",
        "Smart, propulsive, and exactly my kind of twisty.",
        "Changed how I think about the topic. Highly recommend."
    ]

    /// Has the store already been seeded?
    static func hasData(context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<Book>()
        descriptor.fetchLimit = 1
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    @discardableResult
    static func seedIfNeeded(context: ModelContext) -> Bool {
        guard !hasData(context: context) else { return false }
        seed(context: context)
        return true
    }

    /// Inserts the full sample library. Distributes books across shelves and
    /// attaches ~40 sessions to several in-progress / finished books.
    static func seed(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        // Reuse tag objects by genre name so many-to-many is realistic.
        var tagsByName: [String: Tag] = [:]
        func tag(_ name: String, seed: Int) -> Tag {
            if let existing = tagsByName[name] { return existing }
            let t = Tag(name: name, colorSeed: seed)
            context.insert(t)
            tagsByName[name] = t
            return t
        }

        // Mood tags applied to a subset for richer organization.
        let moodNames = ["Cozy", "Page-turner", "Slow burn", "Tearjerker", "Mind-bending"]

        var sessionBudget = 42   // ~40 sessions to spread

        for (i, e) in catalog.enumerated() {
            // Assign shelves: a healthy spread.
            let shelf: Shelf
            switch i % 10 {
            case 0, 1, 2, 3: shelf = .finished      // ~40% finished
            case 4, 5:       shelf = .reading        // ~20% reading
            case 6:          shelf = .dnf            // ~10% dnf
            default:         shelf = .wantToRead     // ~30% tbr
            }

            let colorSeed = i * 7 + 3
            let book = Book(title: e.title,
                            author: e.author,
                            pageCount: e.pages,
                            shelf: shelf,
                            format: BookFormat.allCases[i % BookFormat.allCases.count],
                            colorSeed: colorSeed,
                            seriesName: e.series,
                            seriesNumber: e.seriesNo,
                            dateAdded: calendar.date(byAdding: .day, value: -(i * 6 + 2), to: now) ?? now,
                            isFavorite: i % 8 == 0)

            // Genre tag + an occasional mood tag.
            book.tags.append(tag(e.genre, seed: e.genre.count))
            if i % 4 == 0 {
                let mood = moodNames[i % moodNames.count]
                book.tags.append(tag(mood, seed: mood.count + 11))
            }

            // Per-shelf state.
            switch shelf {
            case .finished:
                let finished = calendar.date(byAdding: .day, value: -((i % 11) * 23 + 5), to: now) ?? now
                let span = 7 + (i % 21)
                let started = calendar.date(byAdding: .day, value: -span, to: finished) ?? finished
                book.startedDate = started
                book.finishedDate = finished
                book.currentPage = e.pages
                book.rating = ratings(for: i)
                if i % 3 == 0 {
                    book.review = sampleReviews[(i / 3) % sampleReviews.count]
                }
            case .reading:
                let started = calendar.date(byAdding: .day, value: -(10 + i % 25), to: now) ?? now
                book.startedDate = started
                book.currentPage = max(20, Int(Double(e.pages) * progressFraction(for: i)))
            case .dnf:
                let started = calendar.date(byAdding: .day, value: -(40 + i % 30), to: now) ?? now
                book.startedDate = started
                book.currentPage = max(10, e.pages / 4)
                book.rating = 2
            case .wantToRead:
                break
            }

            context.insert(book)

            // Spread reading sessions across reading + finished books this year.
            if (shelf == .reading || shelf == .finished), sessionBudget > 0 {
                let count = shelf == .reading ? 3 : 2
                let anchor = book.finishedDate ?? now
                for s in 0..<count {
                    guard sessionBudget > 0 else { break }
                    let daysBack = s * 9 + (i % 7) + 1
                    let date = calendar.date(byAdding: .day, value: -daysBack, to: anchor) ?? anchor
                    // Keep sessions within the current year so the chart populates.
                    let session = ReadingSession(date: clampToYear(date, calendar: calendar),
                                                 pagesRead: 22 + (i + s * 13) % 48,
                                                 minutes: 25 + (i + s * 7) % 55)
                    session.book = book
                    book.sessions.append(session)
                    context.insert(session)
                    sessionBudget -= 1
                }
            }
        }

        try? context.save()
    }

    /// Removes all books, sessions, and tags.
    static func clearAll(context: ModelContext) {
        for book in (try? context.fetch(FetchDescriptor<Book>())) ?? [] {
            context.delete(book)
        }
        for session in (try? context.fetch(FetchDescriptor<ReadingSession>())) ?? [] {
            context.delete(session)
        }
        for tag in (try? context.fetch(FetchDescriptor<Tag>())) ?? [] {
            context.delete(tag)
        }
        try? context.save()
    }

    // MARK: - Helpers

    private static func ratings(for i: Int) -> Double {
        let ladder: [Double] = [5, 4.5, 4, 3.5, 4, 5, 3, 4.5]
        return ladder[i % ladder.count]
    }

    private static func progressFraction(for i: Int) -> Double {
        let ladder: [Double] = [0.18, 0.35, 0.52, 0.7, 0.44, 0.61, 0.27]
        return ladder[i % ladder.count]
    }

    /// Pulls a date into the current calendar year if it drifted earlier,
    /// so the pages-per-month chart always has data to show.
    private static func clampToYear(_ date: Date, calendar: Calendar) -> Date {
        let year = calendar.component(.year, from: .now)
        if calendar.component(.year, from: date) == year { return date }
        // Re-anchor month/day into the current year.
        var comps = calendar.dateComponents([.month, .day], from: date)
        comps.year = year
        return calendar.date(from: comps) ?? date
    }
}
