import Foundation
import SwiftData

/// A tracked moment — either a future date to count down to ("until") or a past
/// date to count up from ("since"). The single user-owned entity in Cusp.
@Model
final class CountdownEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var includeTime: Bool
    /// Raw `EventKind`. Use `kind` to read/write the enum.
    var kindRaw: String
    /// An SF Symbol name or an emoji.
    var symbol: String
    /// Index into `CardTheme` (0..7).
    var colorTag: Int
    /// Raw `RepeatRule`. Use `repeatRule` to read/write the enum.
    var repeatRaw: String
    var note: String
    var pinned: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         title: String = "",
         date: Date = Date(),
         includeTime: Bool = false,
         kind: EventKind = .until,
         symbol: String = "star.fill",
         colorTag: Int = 0,
         repeatRule: RepeatRule = .none,
         note: String = "",
         pinned: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.date = date
        self.includeTime = includeTime
        self.kindRaw = kind.rawValue
        self.symbol = symbol
        self.colorTag = colorTag
        self.repeatRaw = repeatRule.rawValue
        self.note = note
        self.pinned = pinned
        self.createdAt = createdAt
    }

    // MARK: Enum bridges (crash-proof: fall back to sane defaults)

    var kind: EventKind {
        get { EventKind(rawValue: kindRaw) ?? .until }
        set { kindRaw = newValue.rawValue }
    }

    var repeatRule: RepeatRule {
        get { RepeatRule(rawValue: repeatRaw) ?? .none }
        set { repeatRaw = newValue.rawValue }
    }

    var theme: CardTheme {
        get { CardTheme.from(colorTag) }
        set { colorTag = newValue.rawValue }
    }

    /// Whether `symbol` should be rendered as an emoji rather than an SF Symbol.
    var symbolIsEmoji: Bool {
        guard let scalar = symbol.unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && scalar.value > 0x238C
    }
}
