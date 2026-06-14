import Foundation
import SwiftData

/// A single track on a record. Cascade child of `Record`.
@Model
final class Track {
    @Attribute(.unique) var id: UUID
    /// Disc/side label: A, B, C, D …
    var side: String
    /// 1-based position within the side.
    var position: Int
    var title: String
    /// Duration in seconds; 0 means unknown.
    var seconds: Int
    var record: Record?

    init(side: String = "A",
         position: Int = 1,
         title: String = "",
         seconds: Int = 0) {
        self.id = UUID()
        self.side = side.isEmpty ? "A" : side
        self.position = max(1, position)
        self.title = title
        self.seconds = max(0, seconds)
    }

    /// "3:24" or "—" when unknown.
    var durationLabel: String {
        guard seconds > 0 else { return "—" }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
