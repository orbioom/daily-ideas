import Foundation
import SwiftData

/// A daily reflection logged from the Today tab. Snapshots the day's key transit
/// and the profile name so an entry stays readable even if the profile is deleted.
@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Mood on a 1...5 scale.
    var mood: Int
    var note: String
    /// Snapshot of the day's strongest transit, e.g. "Moon trine your Sun".
    var transitSummary: String
    /// Snapshot of the profile this reflection was made for.
    var profileName: String

    init(date: Date = .now,
         mood: Int,
         note: String = "",
         transitSummary: String = "",
         profileName: String = "") {
        self.id = UUID()
        self.date = date
        self.mood = min(max(mood, 1), 5)
        self.note = note
        self.transitSummary = transitSummary
        self.profileName = profileName
    }

    var moodLabel: String {
        switch min(max(mood, 1), 5) {
        case 1: return "Heavy"
        case 2: return "Low"
        case 3: return "Steady"
        case 4: return "Bright"
        default: return "Radiant"
        }
    }

    var moodSymbol: String {
        switch min(max(mood, 1), 5) {
        case 1: return "cloud.rain.fill"
        case 2: return "cloud.fill"
        case 3: return "cloud.sun.fill"
        case 4: return "sun.max.fill"
        default: return "sparkles"
        }
    }
}
