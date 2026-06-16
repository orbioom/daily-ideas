import Foundation
import SwiftData

/// A person whose chart we read. Numerology values are NOT stored — they are
/// computed on demand by `NumerologyEngine` so they always reflect the current
/// numerology system and master-number setting.
@Model
final class Profile {
    var fullName: String
    var birthdate: Date
    var nickname: String
    var createdAt: Date

    init(fullName: String, birthdate: Date, nickname: String = "", createdAt: Date = .now) {
        self.fullName = fullName
        self.birthdate = birthdate
        self.nickname = nickname
        self.createdAt = createdAt
    }

    /// A safe display name that never renders empty.
    var displayName: String {
        let trimmedNick = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNick.isEmpty { return trimmedNick }
        let trimmedFull = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedFull.isEmpty ? "Unnamed" : trimmedFull
    }

    /// First initial for avatars, guarded against empty names.
    var monogram: String {
        let source = displayName
        return String(source.prefix(1)).uppercased()
    }
}
