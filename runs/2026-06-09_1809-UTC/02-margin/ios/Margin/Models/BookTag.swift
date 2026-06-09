import Foundation
import SwiftData
import SwiftUI

/// A user-defined mood / theme tag that can be attached to many books
/// ("cozy", "page-turner", "book club"…). Many-to-many with `Book`.
@Model
final class BookTag {
    var name: String
    var colorHex: String

    /// Inverse of `Book.tags`. Lets SwiftData cleanly unlink this tag from every
    /// book if it is ever deleted (many-to-many, nullify).
    @Relationship(inverse: \Book.tags) var books: [Book] = []

    init(name: String, colorHex: String = "A66A3E") {
        self.name = name
        self.colorHex = colorHex
    }

    /// Parsed color value, falling back to the brand hue.
    var colorValue: UInt32 {
        UInt32(colorHex, radix: 16) ?? 0xA66A3E
    }

    var color: Color { Color(hex: colorValue) }
}
