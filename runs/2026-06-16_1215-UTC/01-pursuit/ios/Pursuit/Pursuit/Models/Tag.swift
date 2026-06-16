import Foundation
import SwiftData
import SwiftUI

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String

    var applications: [Application]

    init(id: UUID = UUID(), name: String, colorHex: String = "4C5BD4") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.applications = []
    }

    var color: Color {
        Color(hex: Tag.parseHex(colorHex))
    }

    static func parseHex(_ string: String) -> UInt {
        let cleaned = string.hasPrefix("#") ? String(string.dropFirst()) : string
        return UInt(cleaned, radix: 16) ?? 0x4C5BD4
    }

    /// Curated palette offered when creating tags (Pro lets users pick freely).
    static let palette: [String] = [
        "4C5BD4", "1F9D5B", "C9871A", "CB3A4A", "2C9CB0",
        "7A5BD4", "D45B9A", "5A5E73", "2C6FD6", "C95B2C"
    ]
}
