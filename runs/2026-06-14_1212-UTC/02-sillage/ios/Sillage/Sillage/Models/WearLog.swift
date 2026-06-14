import Foundation
import SwiftData

/// A single recorded wearing of a fragrance. Cascade-owned by `Fragrance`.
/// Drives last-worn, times-worn, and cost-per-wear.
@Model
final class WearLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Stored as raw string; access via `occasion`. Empty when unspecified.
    var occasionRaw: String
    /// Stored as raw string; access via `season`. Empty when unspecified.
    var seasonRaw: String
    var note: String

    var fragrance: Fragrance?

    init(date: Date = .now,
         occasion: Occasion? = nil,
         season: Season? = nil,
         note: String = "") {
        self.id = UUID()
        self.date = date
        self.occasionRaw = occasion?.rawValue ?? ""
        self.seasonRaw = season?.rawValue ?? ""
        self.note = note
    }

    var occasion: Occasion? {
        get { Occasion(rawValue: occasionRaw) }
        set { occasionRaw = newValue?.rawValue ?? "" }
    }

    var season: Season? {
        get { Season(rawValue: seasonRaw) }
        set { seasonRaw = newValue?.rawValue ?? "" }
    }
}
