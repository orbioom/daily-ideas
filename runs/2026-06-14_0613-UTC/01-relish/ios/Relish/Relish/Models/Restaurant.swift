import Foundation
import SwiftData

@Model
final class Restaurant {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Stored as raw string for SwiftData stability; access via `cuisine`.
    var cuisineRaw: String
    var city: String
    var priceTier: Int          // 1...4
    /// Stored as raw string; access via `sentiment`. Empty when wishlist.
    var sentimentRaw: String
    var rankIndex: Int          // position in global ranked order; lower = better
    var notes: String
    var isWishlist: Bool
    var isFavorite: Bool
    var dateAdded: Date

    @Relationship(deleteRule: .cascade, inverse: \Dish.restaurant)
    var dishes: [Dish]
    @Relationship(deleteRule: .cascade, inverse: \Visit.restaurant)
    var visits: [Visit]

    init(name: String,
         cuisine: Cuisine,
         city: String,
         priceTier: Int,
         sentiment: Sentiment?,
         rankIndex: Int = 0,
         notes: String = "",
         isWishlist: Bool = false,
         isFavorite: Bool = false,
         dateAdded: Date = .now) {
        self.id = UUID()
        self.name = name
        self.cuisineRaw = cuisine.rawValue
        self.city = city
        self.priceTier = min(max(priceTier, 1), 4)
        self.sentimentRaw = sentiment?.rawValue ?? ""
        self.rankIndex = rankIndex
        self.notes = notes
        self.isWishlist = isWishlist
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.dishes = []
        self.visits = []
    }

    var cuisine: Cuisine {
        get { Cuisine(rawValue: cuisineRaw) ?? .other }
        set { cuisineRaw = newValue.rawValue }
    }

    var sentiment: Sentiment? {
        get { Sentiment(rawValue: sentimentRaw) }
        set { sentimentRaw = newValue?.rawValue ?? "" }
    }

    var priceLabel: String {
        let n = min(max(priceTier, 1), 4)
        return String(repeating: "$", count: n)
    }
}
