import Foundation
import SwiftData

enum SeedData {
    static func populate(_ context: ModelContext) {
        func tag(_ name: String) -> Tag {
            let t = Tag(name: name); context.insert(t); return t
        }
        let stoicism = tag("stoicism")
        let time = tag("time")
        let discipline = tag("discipline")
        let nature = tag("nature")
        let strategy = tag("strategy")
        let love = tag("love")
        let solitude = tag("solitude")

        func book(_ title: String, _ author: String, _ category: String, _ color: Int,
                  finished: Bool, _ highlights: [(String, String, String, [Tag], Bool)]) {
            let b = Book(title: title, author: author, category: category, spineColor: color, isFinished: finished)
            context.insert(b)
            for (i, h) in highlights.enumerated() {
                let hl = Highlight(text: h.0, note: h.1, location: h.2, book: b)
                hl.tags = h.3
                hl.isFavorite = h.4
                hl.createdAt = Calendar.current.date(byAdding: .day, value: -(i + color), to: .now) ?? .now
                context.insert(hl)
            }
        }

        book("Meditations", "Marcus Aurelius", "Philosophy", 0, finished: true, [
            ("You have power over your mind — not outside events. Realize this, and you will find strength.",
             "The whole book in one line.", "Book 8", [stoicism, discipline], true),
            ("The happiness of your life depends upon the quality of your thoughts.",
             "", "Book 5", [stoicism], false),
            ("Waste no more time arguing about what a good man should be. Be one.",
             "Stop reading, start doing.", "Book 10", [discipline], true),
            ("Confine yourself to the present.",
             "", "Book 7", [stoicism, time], false)
        ])

        book("Letters from a Stoic", "Seneca", "Philosophy", 4, finished: true, [
            ("We suffer more often in imagination than in reality.",
             "Most fears never arrive.", "Letter 13", [stoicism], true),
            ("It is not that we have a short time to live, but that we waste a lot of it.",
             "On the shortness of life.", "Letter 1", [time, discipline], true),
            ("Begin at once to live, and count each separate day as a separate life.",
             "", "Letter 101", [time], false),
            ("Luck is what happens when preparation meets opportunity.",
             "", "Letter 71", [discipline, strategy], false)
        ])

        book("Walden", "Henry David Thoreau", "Essays", 1, finished: false, [
            ("I went to the woods because I wished to live deliberately.",
             "The reason for the whole experiment.", "Where I Lived", [nature, solitude], true),
            ("Our life is frittered away by detail. Simplify, simplify.",
             "", "Where I Lived", [discipline], false),
            ("The price of anything is the amount of life you exchange for it.",
             "A new way to think about money.", "Economy", [time], true),
            ("I had three chairs in my house; one for solitude, two for friendship, three for society.",
             "", "Visitors", [solitude], false)
        ])

        book("Pride and Prejudice", "Jane Austen", "Fiction", 3, finished: true, [
            ("It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
             "Greatest opening line.", "Chapter 1", [love], true),
            ("I could easily forgive his pride, if he had not mortified mine.",
             "", "Chapter 5", [love], false),
            ("You must allow me to tell you how ardently I admire and love you.",
             "Darcy's first proposal.", "Chapter 34", [love], true)
        ])

        book("The Art of War", "Sun Tzu", "Philosophy", 5, finished: true, [
            ("The supreme art of war is to subdue the enemy without fighting.",
             "Win before the battle.", "III. Attack by Stratagem", [strategy], true),
            ("In the midst of chaos, there is also opportunity.",
             "", "VII. Maneuvering", [strategy], false),
            ("Victorious warriors win first and then go to war.",
             "Preparation over hope.", "IV. Tactical Dispositions", [strategy, discipline], true)
        ])

        book("Leaves of Grass", "Walt Whitman", "Poetry", 6, finished: false, [
            ("I exist as I am, that is enough.",
             "", "Song of Myself", [solitude], true),
            ("Keep your face always toward the sunshine — and shadows will fall behind you.",
             "", "", [nature], false),
            ("I am large, I contain multitudes.",
             "On contradiction.", "Song of Myself", [], true)
        ])

        try? context.save()
    }
}
