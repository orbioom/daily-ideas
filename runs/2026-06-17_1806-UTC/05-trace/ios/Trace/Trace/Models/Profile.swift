import Foundation
import SwiftData
import SwiftUI

@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: Int
    var age: Int?
    var createdAt: Date

    init(id: UUID = UUID(), name: String, colorHex: Int, age: Int? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.age = age
        self.createdAt = createdAt
    }

    var avatarColor: Color { Color(hex: UInt(bitPattern: colorHex) & 0xFFFFFF) }

    /// First letter for the avatar bubble; falls back to a star.
    var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "★" }
        return String(first).uppercased()
    }
}

/// The fixed palette parents can pick avatar colors from.
enum AvatarPalette {
    static let colors: [Int] = [
        0xFF8A4C, 0x4C8AFF, 0x9B5CE0, 0x4CC26A,
        0xFF5CA8, 0xFFC23C, 0x3DAEAE, 0xE0653C
    ]
}
