import Foundation
import SwiftData
import SwiftUI

/// A single check-in: how you felt at a moment, what you were doing, and a note.
@Model
final class MoodEntry {
    var id: UUID
    var date: Date
    /// 1 (rough) ... 5 (great).
    var mood: Int
    var note: String
    @Relationship var activities: [Activity]

    init(id: UUID = UUID(),
         date: Date = .now,
         mood: Int = 3,
         note: String = "",
         activities: [Activity] = []) {
        self.id = id
        self.date = date
        self.mood = max(1, min(5, mood))
        self.note = note
        self.activities = activities
    }
}

/// Shared vocabulary for the five mood levels.
enum Mood {
    static let levels = 1...5

    static func label(_ value: Int) -> String {
        switch value {
        case 1: return "Rough"
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        default: return "Great"
        }
    }

    static func symbol(_ value: Int) -> String {
        switch value {
        case 1: return "cloud.rain.fill"
        case 2: return "cloud.fill"
        case 3: return "cloud.sun.fill"
        case 4: return "sun.max.fill"
        default: return "sparkles"
        }
    }

    static func color(_ value: Int) -> Color {
        switch value {
        case 1: return Color(hex: 0x6E7BA8)
        case 2: return Color(hex: 0x6E93B8)
        case 3: return Color(hex: 0x5FA9A0)
        case 4: return Color(hex: 0x6FB97E)
        default: return Color(hex: 0x86C79A)
        }
    }
}
