import Foundation
import SwiftData

/// A support / opening act remembered from a concert. Owned (cascade) child of `Concert`.
@Model
final class SupportAct {
    @Attribute(.unique) var id: UUID
    /// Order of appearance on the bill; lower = earlier.
    var order: Int
    var name: String
    var concert: Concert?

    init(order: Int, name: String) {
        self.id = UUID()
        self.order = order
        self.name = name
    }
}
