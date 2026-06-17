import Foundation
import SwiftData

@Model
final class GlyphProgress {
    @Attribute(.unique) var id: UUID
    var profileID: UUID
    var glyphKey: String
    var bestStars: Int
    var attempts: Int
    var lastPracticed: Date

    init(
        id: UUID = UUID(),
        profileID: UUID,
        glyphKey: String,
        bestStars: Int = 0,
        attempts: Int = 0,
        lastPracticed: Date = .now
    ) {
        self.id = id
        self.profileID = profileID
        self.glyphKey = glyphKey
        self.bestStars = bestStars
        self.attempts = attempts
        self.lastPracticed = lastPracticed
    }
}
