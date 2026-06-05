import Foundation
import SwiftData

/// A person within a group. Members are just names within a group — no external
/// accounts. `colorHue` indexes the calm member palette in Brand.
@Model
final class Member {
    var id: UUID
    var name: String
    /// Index into Brand.memberPalette (wraps via modulo).
    var colorHue: Int
    var createdAt: Date

    /// Owning group. Optional so SwiftData can manage the inverse relationship.
    var group: SplitGroup?

    init(id: UUID = UUID(),
         name: String,
         colorHue: Int = 0,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorHue = colorHue
        self.createdAt = createdAt
    }
}
