import SwiftData
import Foundation

@Model
class Article {
    var id: UUID
    var title: String
    var content: String
    var source: String
    var dateAdded: Date
    var wordCount: Int
    var isArchived: Bool

    @Relationship(deleteRule: .cascade) var sessions: [ReadingSession] = []

    var isCompleted: Bool {
        sessions.contains { $0.completed }
    }

    var progressFraction: Double {
        guard wordCount > 0 else { return 0 }
        let lastSession = sessions.max(by: { $0.date < $1.date })
        guard let s = lastSession else { return 0 }
        if s.completed { return 1 }
        return min(1.0, Double(s.wordIndex) / Double(wordCount))
    }

    var lastReadDate: Date? {
        sessions.max(by: { $0.date < $1.date })?.date
    }

    var totalReadingMinutes: Int {
        Int(sessions.map(\.durationSeconds).reduce(0, +) / 60)
    }

    init(title: String, content: String, source: String = "Pasted Text") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.source = source
        self.dateAdded = Date()
        let wds = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        self.wordCount = wds.count
        self.isArchived = false
    }
}

@Model
class ReadingSession {
    var id: UUID
    var date: Date
    var wordIndex: Int      // index into words array where we stopped
    var speedWPM: Int
    var durationSeconds: Double
    var completed: Bool

    var article: Article?

    init(wordIndex: Int, speedWPM: Int, durationSeconds: Double, completed: Bool) {
        self.id = UUID()
        self.date = Date()
        self.wordIndex = wordIndex
        self.speedWPM = speedWPM
        self.durationSeconds = durationSeconds
        self.completed = completed
    }
}
