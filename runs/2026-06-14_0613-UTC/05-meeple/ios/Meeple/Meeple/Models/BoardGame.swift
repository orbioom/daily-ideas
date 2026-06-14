import Foundation
import SwiftData

@Model
final class BoardGame {
    @Attribute(.unique) var id: UUID
    var title: String
    var designer: String
    var minPlayers: Int
    var maxPlayers: Int
    var playTimeMin: Int
    var weight: Double            // BGG-style complexity 1.0...5.0
    var yearPublished: Int
    var statusRaw: String
    var rating: Int              // 0...10
    var notes: String
    var coverHue: Int            // deterministic gradient seed
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Play.game)
    var plays: [Play]

    init(
        id: UUID = UUID(),
        title: String,
        designer: String,
        minPlayers: Int,
        maxPlayers: Int,
        playTimeMin: Int,
        weight: Double,
        yearPublished: Int,
        status: CollectionStatus = .owned,
        rating: Int = 0,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.designer = designer
        self.minPlayers = max(1, minPlayers)
        self.maxPlayers = max(minPlayers, maxPlayers)
        self.playTimeMin = max(0, playTimeMin)
        self.weight = min(5.0, max(1.0, weight))
        self.yearPublished = yearPublished
        self.statusRaw = status.rawValue
        self.rating = min(10, max(0, rating))
        self.notes = notes
        self.coverHue = BoardGame.hue(for: title)
        self.createdAt = createdAt
        self.plays = []
    }

    /// Deterministic hue (0...359) from the title so covers are stable.
    static func hue(for title: String) -> Int {
        var hash: UInt64 = 5381
        for byte in title.utf8 {
            hash = (hash &* 33) &+ UInt64(byte)
        }
        return Int(hash % 360)
    }

    // MARK: - Computed

    var status: CollectionStatus {
        get { CollectionStatus(rawValue: statusRaw) ?? .owned }
        set { statusRaw = newValue.rawValue }
    }

    var playCount: Int { plays.count }

    var lastPlayed: Date? {
        plays.map(\.date).max()
    }

    var playerRangeText: String {
        if minPlayers == maxPlayers { return "\(minPlayers)" }
        return "\(minPlayers)–\(maxPlayers)"
    }

    var initials: String {
        let words = title.split(separator: " ").prefix(2)
        let chars = words.compactMap { $0.first }.map { String($0) }
        let joined = chars.joined().uppercased()
        if joined.isEmpty { return "??" }
        return joined
    }

    /// One of two cover symbols, deterministic from coverHue.
    var coverSymbol: String {
        coverHue % 2 == 0 ? "die.face.5" : "squareshape.split.3x3"
    }
}
