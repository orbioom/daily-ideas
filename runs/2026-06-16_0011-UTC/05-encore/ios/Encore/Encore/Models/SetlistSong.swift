import Foundation
import SwiftData

/// One song remembered from a concert's setlist. Owned (cascade) child of `Concert`.
@Model
final class SetlistSong {
    @Attribute(.unique) var id: UUID
    /// Position in the setlist; lower = earlier in the show.
    var order: Int
    var title: String
    var isEncore: Bool
    var isHighlight: Bool
    var concert: Concert?

    init(order: Int,
         title: String,
         isEncore: Bool = false,
         isHighlight: Bool = false) {
        self.id = UUID()
        self.order = order
        self.title = title
        self.isEncore = isEncore
        self.isHighlight = isHighlight
    }
}
