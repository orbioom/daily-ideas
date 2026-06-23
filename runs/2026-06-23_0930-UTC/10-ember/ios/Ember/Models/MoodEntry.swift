import Foundation
import SwiftData

/// A standalone daily mood check-in (1...5). Sessions also capture pre/post mood,
/// but this lets the user log how they feel independent of breathing.
@Model
final class MoodEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// 1 (low) ... 5 (great).
    var score: Int
    var note: String

    init(id: UUID = UUID(), date: Date = .now, score: Int, note: String = "") {
        self.id = id
        self.date = date
        self.score = max(1, min(5, score))
        self.note = note
    }
}

/// Display helpers shared by mood UI throughout the app.
enum Mood {
    static let range = 1...5

    static func label(_ score: Int) -> String {
        switch max(1, min(5, score)) {
        case 1: return "Rough"
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        default: return "Great"
        }
    }

    static func emoji(_ score: Int) -> String {
        switch max(1, min(5, score)) {
        case 1: return "😔"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        default: return "😄"
        }
    }
}
