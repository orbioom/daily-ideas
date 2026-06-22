import Foundation
import SwiftData

@Model
class CustomWordList {
    var id: UUID
    var name: String
    var words: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        words: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.words = words
        self.createdAt = createdAt
    }

    var wordCount: Int {
        words.count
    }

    var isValid: Bool {
        words.count >= 5
    }

    var displayWords: String {
        words.prefix(3).joined(separator: ", ") + (words.count > 3 ? "..." : "")
    }
}
