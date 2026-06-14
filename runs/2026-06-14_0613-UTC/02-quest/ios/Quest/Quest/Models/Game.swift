import Foundation
import SwiftData

@Model
final class Game {
    @Attribute(.unique) var id: UUID
    var title: String

    // Stored as raw strings for SwiftData stability; accessed via typed helpers below.
    var platformRaw: String
    var genreRaw: String
    var statusRaw: String

    var personalRating: Int          // 0...10, 0 = unrated
    var mainStoryHours: Double       // user estimate of length; 0 = unknown
    var notes: String
    var dateAdded: Date
    var dateCompleted: Date?
    var isFavorite: Bool
    var coverHue: Double             // 0...1 deterministic from title

    @Relationship(deleteRule: .cascade, inverse: \PlaySession.game)
    var sessions: [PlaySession]

    init(title: String,
         platform: Platform,
         genre: Genre,
         status: GameStatus,
         personalRating: Int = 0,
         mainStoryHours: Double = 0,
         notes: String = "",
         dateAdded: Date = .now,
         dateCompleted: Date? = nil,
         isFavorite: Bool = false,
         sessions: [PlaySession] = []) {
        self.id = UUID()
        self.title = title
        self.platformRaw = platform.rawValue
        self.genreRaw = genre.rawValue
        self.statusRaw = status.rawValue
        self.personalRating = personalRating
        self.mainStoryHours = mainStoryHours
        self.notes = notes
        self.dateAdded = dateAdded
        self.dateCompleted = dateCompleted
        self.isFavorite = isFavorite
        self.coverHue = Game.hue(for: title)
        self.sessions = sessions
    }

    // MARK: Typed accessors (fall back gracefully if data is unexpected)

    var platform: Platform {
        get { Platform(rawValue: platformRaw) ?? .other }
        set { platformRaw = newValue.rawValue }
    }

    var genre: Genre {
        get { Genre(rawValue: genreRaw) ?? .other }
        set { genreRaw = newValue.rawValue }
    }

    var status: GameStatus {
        get { GameStatus(rawValue: statusRaw) ?? .backlog }
        set { statusRaw = newValue.rawValue }
    }

    // MARK: Derived

    /// Total hours logged across all play sessions.
    var hoursLogged: Double {
        sessions.reduce(0) { $0 + max(0, $1.hours) }
    }

    /// Percent of the user's length estimate completed (0...100), guarded.
    var estimatePercent: Double {
        guard mainStoryHours > 0 else { return 0 }
        return min(100, max(0, hoursLogged / mainStoryHours * 100))
    }

    var initials: String {
        let words = title
            .split(whereSeparator: { $0 == " " || $0 == ":" || $0 == "-" })
            .filter { !$0.isEmpty }
        let letters = words.prefix(2).compactMap { $0.first }
        let s = String(letters).uppercased()
        return s.isEmpty ? "?" : s
    }

    /// Deterministic hue 0...1 from the title so a game's generated cover is stable.
    static func hue(for title: String) -> Double {
        var hash: UInt64 = 1469598103934665603
        for byte in title.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return Double(hash % 1000) / 1000.0
    }
}
