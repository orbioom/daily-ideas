import Foundation
import SwiftData

enum Mood: String, Codable, CaseIterable {
    case great, good, neutral, low, rough

    var emoji: String {
        switch self {
        case .great:   return "😄"
        case .good:    return "🙂"
        case .neutral: return "😐"
        case .low:     return "😔"
        case .rough:   return "😣"
        }
    }

    var label: String { rawValue.capitalized }

    var color: String {
        switch self {
        case .great:   return "MoodGreat"
        case .good:    return "MoodGood"
        case .neutral: return "MoodNeutral"
        case .low:     return "MoodLow"
        case .rough:   return "MoodRough"
        }
    }
}

@Model
class VoiceEntry {
    var id: UUID
    var date: Date
    var audioFilename: String        // stored in DocumentDirectory/MurmurAudio/
    var transcript: String
    var durationSeconds: Double
    var moodRaw: String              // Mood.rawValue
    var tags: [String]
    var title: String                // auto-generated or user-edited
    var isFavorite: Bool
    var isTranscribing: Bool         // ephemeral flag, persisted as false on save
    var transcriptConfidence: Float

    init(date: Date = .now, audioFilename: String, durationSeconds: Double = 0) {
        self.id = UUID()
        self.date = date
        self.audioFilename = audioFilename
        self.transcript = ""
        self.durationSeconds = durationSeconds
        self.moodRaw = Mood.neutral.rawValue
        self.tags = []
        self.title = ""
        self.isFavorite = false
        self.isTranscribing = false
        self.transcriptConfidence = 0
    }

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }

    var displayTitle: String {
        title.isEmpty ? formattedDate : title
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var formattedDuration: String {
        let s = Int(durationSeconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    var wordCount: Int { transcript.split(separator: " ").count }
}

@Model
class JournalTag {
    var name: String
    var usageCount: Int

    init(name: String) {
        self.name = name
        self.usageCount = 1
    }
}
