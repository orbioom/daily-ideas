import Foundation
import SwiftUI

/// Where a book sits in the reader's journey.
enum ReadingStatus: String, CaseIterable, Identifiable, Codable {
    case wantToRead, reading, finished, dnf

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wantToRead: return "Want to read"
        case .reading: return "Reading"
        case .finished: return "Finished"
        case .dnf: return "Did not finish"
        }
    }

    var symbol: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .reading: return "book"
        case .finished: return "checkmark.seal.fill"
        case .dnf: return "xmark.bin"
        }
    }

    var tint: Color {
        switch self {
        case .wantToRead: return Brand.info
        case .reading: return Brand.magic
        case .finished: return Brand.live
        case .dnf: return Brand.text3
        }
    }
}

/// Broad literary genre used for filtering and analytics.
enum BookGenre: String, CaseIterable, Identifiable, Codable {
    case fiction, nonfiction, sciFi, fantasy, mystery, thriller, romance, biography, history, selfHelp, poetry, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fiction: return "Fiction"
        case .nonfiction: return "Nonfiction"
        case .sciFi: return "Sci-Fi"
        case .fantasy: return "Fantasy"
        case .mystery: return "Mystery"
        case .thriller: return "Thriller"
        case .romance: return "Romance"
        case .biography: return "Biography"
        case .history: return "History"
        case .selfHelp: return "Self-help"
        case .poetry: return "Poetry"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .fiction: return "books.vertical"
        case .nonfiction: return "doc.text"
        case .sciFi: return "sparkles"
        case .fantasy: return "wand.and.stars"
        case .mystery: return "magnifyingglass"
        case .thriller: return "bolt"
        case .romance: return "heart"
        case .biography: return "person.crop.rectangle"
        case .history: return "clock.arrow.circlepath"
        case .selfHelp: return "lightbulb"
        case .poetry: return "text.quote"
        case .other: return "book.closed"
        }
    }
}

/// The medium the reader consumed a book in.
enum BookFormat: String, CaseIterable, Identifiable, Codable {
    case paper, ebook, audio

    var id: String { rawValue }

    var label: String {
        switch self {
        case .paper: return "Paper"
        case .ebook: return "Ebook"
        case .audio: return "Audiobook"
        }
    }

    var symbol: String {
        switch self {
        case .paper: return "book.closed"
        case .ebook: return "ipad"
        case .audio: return "headphones"
        }
    }
}
