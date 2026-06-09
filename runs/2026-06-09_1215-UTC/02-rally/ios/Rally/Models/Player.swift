import Foundation
import SwiftData

/// A person who plays matches: you, an opponent, or a partner. `isMe` marks the
/// single "You" record whose rating and record the app foregrounds. Ratings use
/// a DUPR-like 2.0–6.0 scale that the `RatingEngine` evolves after each match.
@Model
final class Player {
    var name: String
    var isMe: Bool
    var rating: Double
    var note: String
    var createdAt: Date

    init(name: String,
         isMe: Bool = false,
         rating: Double = 3.0,
         note: String = "",
         createdAt: Date = .now) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isMe = isMe
        self.rating = Player.clampRating(rating)
        self.note = note
        self.createdAt = createdAt
    }

    /// Keeps every stored rating inside the supported scale.
    static func clampRating(_ value: Double) -> Double {
        min(max(value, 2.0), 6.0)
    }

    /// A short, friendly initials badge ("AB", "Y").
    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init)
        let joined = letters.joined().uppercased()
        return joined.isEmpty ? "?" : joined
    }

    var ratingText: String {
        String(format: "%.2f", rating)
    }
}
