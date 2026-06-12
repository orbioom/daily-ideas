import Foundation
import SwiftData
import SwiftUI

/// Deterministic, launch-stable hue (0...1) from a string via FNV-1a.
enum StableHue {
    static func hue(for s: String) -> Double {
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return Double(h % 360) / 360.0
    }
}

enum GameStatus: String, Codable, CaseIterable, Identifiable {
    case wishlist, backlog, playing, beaten, completed, abandoned
    var id: String { rawValue }
    var label: String {
        switch self {
        case .wishlist: return "Wishlist"
        case .backlog: return "Backlog"
        case .playing: return "Playing"
        case .beaten: return "Beaten"
        case .completed: return "100%"
        case .abandoned: return "Abandoned"
        }
    }
    var symbol: String {
        switch self {
        case .wishlist: return "heart"
        case .backlog: return "tray.full"
        case .playing: return "gamecontroller.fill"
        case .beaten: return "flag.checkered"
        case .completed: return "trophy.fill"
        case .abandoned: return "xmark.bin"
        }
    }
    var tint: Color {
        switch self {
        case .wishlist: return Color(red: 0.92, green: 0.45, blue: 0.62)
        case .backlog: return Color(red: 0.55, green: 0.55, blue: 0.65)
        case .playing: return Color(red: 0.36, green: 0.72, blue: 0.98)
        case .beaten: return Color(red: 0.34, green: 0.78, blue: 0.52)
        case .completed: return Color(red: 0.98, green: 0.76, blue: 0.30)
        case .abandoned: return Color(red: 0.78, green: 0.36, blue: 0.36)
        }
    }
    /// Counts toward "in your pile" (owned, not finished).
    var isPile: Bool { self == .backlog || self == .playing }
    /// Counts as a finished game for completion-rate purposes.
    var isFinished: Bool { self == .beaten || self == .completed }
}

enum Platform: String, Codable, CaseIterable, Identifiable {
    case ps5 = "PS5", ps4 = "PS4", xbox = "Xbox", switchC = "Switch", pc = "PC"
    case steamDeck = "Steam Deck", mobile = "Mobile", retro = "Retro", other = "Other"
    var id: String { rawValue }
}

enum Genre: String, Codable, CaseIterable, Identifiable {
    case action = "Action", rpg = "RPG", shooter = "Shooter", strategy = "Strategy"
    case adventure = "Adventure", platformer = "Platformer", puzzle = "Puzzle"
    case racing = "Racing", sports = "Sports", sim = "Simulation"
    case horror = "Horror", indie = "Indie", fighting = "Fighting", other = "Other"
    var id: String { rawValue }
}

enum Priority: Int, Codable, CaseIterable, Identifiable {
    case someday = 0, low = 1, medium = 2, high = 3, next = 4
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .someday: return "Someday"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .next: return "Play next"
        }
    }
}

@Model
final class Game {
    @Attribute(.unique) var id: UUID
    var title: String
    var platformRaw: String
    var genreRaw: String
    var statusRaw: String
    var priorityRaw: Int
    /// 0...10 = half-star steps (e.g. 7 == 3.5 stars). 0 means unrated.
    var ratingHalf: Int
    var hoursPlayed: Double
    /// Estimated "main story" length in hours, à la HowLongToBeat.
    var estimatedHours: Double
    var pricePaid: Double
    var dateAdded: Date
    var dateStarted: Date?
    var dateFinished: Date?
    var notes: String
    /// Deterministic hue so each cover swatch is stable and distinct.
    var coverHue: Double

    @Relationship(deleteRule: .cascade, inverse: \PlaySession.game)
    var sessions: [PlaySession] = []

    init(title: String, platform: Platform = .pc, genre: Genre = .action,
         status: GameStatus = .backlog, priority: Priority = .medium,
         ratingHalf: Int = 0, hoursPlayed: Double = 0, estimatedHours: Double = 0,
         pricePaid: Double = 0, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.platformRaw = platform.rawValue
        self.genreRaw = genre.rawValue
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.ratingHalf = ratingHalf
        self.hoursPlayed = hoursPlayed
        self.estimatedHours = estimatedHours
        self.pricePaid = pricePaid
        self.dateAdded = Date()
        self.notes = notes
        self.coverHue = StableHue.hue(for: title)
    }

    var status: GameStatus {
        get { GameStatus(rawValue: statusRaw) ?? .backlog }
        set { statusRaw = newValue.rawValue }
    }
    var platform: Platform {
        get { Platform(rawValue: platformRaw) ?? .other }
        set { platformRaw = newValue.rawValue }
    }
    var genre: Genre {
        get { Genre(rawValue: genreRaw) ?? .other }
        set { genreRaw = newValue.rawValue }
    }
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    var rating: Double { Double(ratingHalf) / 2.0 }

    /// Completion fraction of the estimated length (capped at 1).
    var completion: Double {
        guard estimatedHours > 0 else { return status.isFinished ? 1 : 0 }
        return min(hoursPlayed / estimatedHours, 1)
    }

    /// Hours still expected to finish from here (0 if already finished).
    var hoursRemaining: Double {
        guard !status.isFinished, estimatedHours > 0 else { return 0 }
        return max(estimatedHours - hoursPlayed, 0)
    }
}

@Model
final class PlaySession {
    var date: Date
    var hours: Double
    var note: String
    var game: Game?

    init(date: Date = Date(), hours: Double, note: String = "") {
        self.date = date
        self.hours = hours
        self.note = note
    }
}
