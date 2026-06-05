import Foundation
import SwiftData

/// One structured tasting session for a bottle — the moment captured: rating,
/// the aroma / palate / finish triad, free-form descriptors, and an overall note.
@Model
final class Tasting {
    var date: Date
    /// 1...5; clamped on write.
    var ratingRaw: Int
    var aroma: String
    var palate: String
    var finish: String
    var overallNote: String
    /// Free descriptors chosen from the category lexicon (or typed).
    var flavorTags: [String]

    var bottle: Bottle?

    init(date: Date = .now,
         rating: Int = 3,
         aroma: String = "",
         palate: String = "",
         finish: String = "",
         overallNote: String = "",
         flavorTags: [String] = []) {
        self.date = date
        self.ratingRaw = min(5, max(1, rating))
        self.aroma = aroma
        self.palate = palate
        self.finish = finish
        self.overallNote = overallNote
        self.flavorTags = flavorTags
    }

    /// Rating with a guarded setter so it can never fall outside 1...5.
    var rating: Int {
        get { min(5, max(1, ratingRaw)) }
        set { ratingRaw = min(5, max(1, newValue)) }
    }
}
