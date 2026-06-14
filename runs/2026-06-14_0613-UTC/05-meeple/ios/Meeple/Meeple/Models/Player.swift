import Foundation
import SwiftData

@Model
final class Player {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHue: Int
    var isMe: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHue: Int? = nil,
        isMe: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorHue = colorHue ?? Player.hue(for: name)
        self.isMe = isMe
        self.createdAt = createdAt
    }

    static func hue(for name: String) -> Int {
        var hash: UInt64 = 7919
        for byte in name.utf8 {
            hash = (hash &* 31) &+ UInt64(byte)
        }
        return Int(hash % 360)
    }

    var initials: String {
        let words = name.split(separator: " ").prefix(2)
        let chars = words.compactMap { $0.first }.map { String($0) }
        let joined = chars.joined().uppercased()
        return joined.isEmpty ? "?" : joined
    }
}
