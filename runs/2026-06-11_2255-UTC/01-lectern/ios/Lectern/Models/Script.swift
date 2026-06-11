import Foundation
import SwiftData

@Model
final class Script {
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var lastPlayedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \RehearsalSession.script)
    var sessions: [RehearsalSession] = []

    init(title: String, body: String, createdAt: Date = .now, isFavorite: Bool = false) {
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isFavorite = isFavorite
    }

    var wordCount: Int { TextStats.wordCount(body) }

    /// Paragraphs of the script, blank lines removed.
    var paragraphs: [String] {
        body.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
