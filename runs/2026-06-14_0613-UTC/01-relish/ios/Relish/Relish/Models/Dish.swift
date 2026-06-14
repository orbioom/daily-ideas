import Foundation
import SwiftData

@Model
final class Dish {
    @Attribute(.unique) var id: UUID
    var name: String
    var rating: Int           // 1...5
    var notes: String
    var wouldOrderAgain: Bool
    var restaurant: Restaurant?

    init(name: String,
         rating: Int,
         notes: String = "",
         wouldOrderAgain: Bool = true) {
        self.id = UUID()
        self.name = name
        self.rating = min(max(rating, 1), 5)
        self.notes = notes
        self.wouldOrderAgain = wouldOrderAgain
    }
}
