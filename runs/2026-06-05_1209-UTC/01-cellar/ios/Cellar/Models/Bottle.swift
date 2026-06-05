import Foundation
import SwiftData

/// A thing you taste and want to remember — a coffee bag, a bottle of wine,
/// a dram of whisky. The cellar's primary record; owns a cascade of tastings.
@Model
final class Bottle {
    var name: String
    var producer: String
    var origin: String
    /// Stored as the category raw value for tolerant decoding.
    var categoryRaw: String
    /// Optional vintage / roast year / age statement.
    var year: Int?
    var notes: String
    /// Hex of the chip color shown as a faux label; defaults to the category tint.
    var colorHex: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Tasting.bottle)
    var tastings: [Tasting]

    init(name: String,
         producer: String = "",
         origin: String = "",
         category: TastingCategory = .coffee,
         year: Int? = nil,
         notes: String = "",
         colorHex: Int? = nil,
         createdAt: Date = .now) {
        self.name = name
        self.producer = producer
        self.origin = origin
        self.categoryRaw = category.rawValue
        self.year = year
        self.notes = notes
        self.colorHex = colorHex ?? Int(category.tintHex)
        self.createdAt = createdAt
        self.tastings = []
    }

    /// Tolerant accessor — falls back to coffee if a legacy/unknown raw value appears.
    var category: TastingCategory {
        get { TastingCategory(rawValue: categoryRaw) ?? .coffee }
        set { categoryRaw = newValue.rawValue }
    }

    var tastingCount: Int { tastings.count }

    /// Average of all tasting ratings, or nil when never tasted.
    var averageRating: Double? {
        guard !tastings.isEmpty else { return nil }
        let total = tastings.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(tastings.count)
    }

    /// Most recent tasting date, if any.
    var lastTastedAt: Date? {
        tastings.map(\.date).max()
    }
}
