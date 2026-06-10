import Foundation
import SwiftData

/// A photo the user chose to keep, so it never reappears in a review deck.
/// We persist only the asset's local identifier — never the image itself.
@Model
final class KeptPhoto {
    @Attribute(.unique) var localIdentifier: String
    var keptAt: Date

    init(localIdentifier: String) {
        self.localIdentifier = localIdentifier
        self.keptAt = .now
    }
}

/// A completed cleanup session — powers the history and reclaimed-space stats.
@Model
final class CleanSession {
    var id: UUID
    var date: Date
    var reviewedCount: Int
    var deletedCount: Int
    var bytesReclaimed: Int64

    init(reviewedCount: Int, deletedCount: Int, bytesReclaimed: Int64) {
        self.id = UUID()
        self.date = .now
        self.reviewedCount = reviewedCount
        self.deletedCount = deletedCount
        self.bytesReclaimed = bytesReclaimed
    }
}
