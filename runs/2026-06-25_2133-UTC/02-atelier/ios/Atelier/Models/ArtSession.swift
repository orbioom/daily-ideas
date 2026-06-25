import Foundation
import SwiftData

enum ArtMedium: String, Codable, CaseIterable, Identifiable {
    case pencil = "Pencil"
    case charcoal = "Charcoal"
    case ink = "Ink"
    case watercolor = "Watercolor"
    case acrylic = "Acrylic"
    case oil = "Oil"
    case gouache = "Gouache"
    case pastel = "Pastel"
    case digital = "Digital"
    case mixedMedia = "Mixed Media"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .pencil, .charcoal: return "pencil"
        case .ink: return "paintbrush.pointed.fill"
        case .watercolor, .gouache: return "drop.fill"
        case .acrylic, .oil: return "paintpalette.fill"
        case .pastel: return "scribble.variable"
        case .digital: return "ipad.and.apple.pencil"
        case .mixedMedia: return "star.square.on.square"
        }
    }
}

enum SessionMood: String, Codable, CaseIterable, Identifiable {
    case excellent = "Excellent"
    case good = "Good"
    case okay = "Okay"
    case frustrated = "Frustrated"
    case blocked = "Blocked"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .excellent: return "🔥"
        case .good: return "😊"
        case .okay: return "😐"
        case .frustrated: return "😤"
        case .blocked: return "😶"
        }
    }
}

enum PracticeType: String, Codable, CaseIterable, Identifiable {
    case fundamentals = "Fundamentals"
    case study = "Study"
    case sketch = "Sketch"
    case fullPiece = "Full Piece"
    case exercise = "Exercise"
    case freePlay = "Free Play"
    case copy = "Master Copy"

    var id: String { rawValue }
}

@Model
final class ArtSession {
    var id: UUID = UUID()
    var date: Date = Date.now
    var durationMinutes: Int = 60
    var medium: ArtMedium = ArtMedium.pencil
    var practiceType: PracticeType = PracticeType.sketch
    var subject: String = ""
    var skillWorked: String = ""
    var mood: SessionMood = SessionMood.good
    var notes: String = ""
    var rating: Int = 3

    init(
        date: Date = .now,
        durationMinutes: Int = 60,
        medium: ArtMedium = .pencil,
        practiceType: PracticeType = .sketch,
        subject: String = "",
        skillWorked: String = "",
        mood: SessionMood = .good,
        notes: String = "",
        rating: Int = 3
    ) {
        self.id = UUID()
        self.date = date
        self.durationMinutes = durationMinutes
        self.medium = medium
        self.practiceType = practiceType
        self.subject = subject
        self.skillWorked = skillWorked
        self.mood = mood
        self.notes = notes
        self.rating = rating
    }

    var durationFormatted: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
