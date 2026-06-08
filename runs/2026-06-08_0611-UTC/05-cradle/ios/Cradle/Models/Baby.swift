import SwiftUI
import SwiftData

// MARK: - Enums

enum Sex: String, Codable, CaseIterable {
    case boy, girl, unspecified

    var label: String {
        switch self {
        case .boy: return "Boy"
        case .girl: return "Girl"
        case .unspecified: return "Unspecified"
        }
    }

    var symbol: String {
        switch self {
        case .boy: return "person.fill"
        case .girl: return "person.fill"
        case .unspecified: return "person.fill"
        }
    }
}

enum EventKind: String, Codable, CaseIterable {
    case feed, sleep, diaper, pump, note

    var label: String {
        switch self {
        case .feed: return "Feed"
        case .sleep: return "Sleep"
        case .diaper: return "Diaper"
        case .pump: return "Pump"
        case .note: return "Note"
        }
    }

    var symbol: String {
        switch self {
        case .feed: return "drop.fill"
        case .sleep: return "moon.fill"
        case .diaper: return "heart.fill"
        case .pump: return "arrow.up.and.down.circle.fill"
        case .note: return "note.text"
        }
    }

    var color: Color {
        switch self {
        case .feed: return Brand.info
        case .sleep: return Brand.magic
        case .diaper: return Brand.warn
        case .pump: return Brand.live
        case .note: return Brand.text2
        }
    }
}

enum FeedType: String, Codable, CaseIterable {
    case breast, bottle, solid

    var label: String {
        switch self {
        case .breast: return "Breast"
        case .bottle: return "Bottle"
        case .solid: return "Solid"
        }
    }

    var symbol: String {
        switch self {
        case .breast: return "heart.circle.fill"
        case .bottle: return "drop.circle.fill"
        case .solid: return "fork.knife"
        }
    }
}

enum Side: String, Codable, CaseIterable {
    case left, right, both

    var label: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .both: return "Both"
        }
    }
}

enum DiaperType: String, Codable, CaseIterable {
    case wet, dirty, mixed

    var label: String {
        switch self {
        case .wet: return "Wet"
        case .dirty: return "Dirty"
        case .mixed: return "Mixed"
        }
    }

    var symbol: String {
        switch self {
        case .wet: return "drop.fill"
        case .dirty: return "circle.fill"
        case .mixed: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Baby Model

@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date
    var sex: Sex
    var symbol: String
    var colorHex: UInt32
    var order: Int

    @Relationship(deleteRule: .cascade)
    var events: [CareEvent]

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        sex: Sex = .unspecified,
        symbol: String = "star.fill",
        colorHex: UInt32 = 0x4E6BA8,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.sex = sex
        self.symbol = symbol
        self.colorHex = colorHex
        self.order = order
        self.events = []
    }

    var accentColor: Color {
        Color(hex: colorHex)
    }

    var ageString: String {
        Format.age(from: birthDate)
    }
}

// MARK: - CareEvent Model

@Model
final class CareEvent {
    var id: UUID
    var kind: EventKind
    var startTime: Date
    var endTime: Date?

    // Feed fields
    var feedType: FeedType?
    var amountML: Double?
    var breastSide: Side?

    // Diaper fields
    var diaperType: DiaperType?

    // Common
    var note: String

    var baby: Baby?

    init(
        id: UUID = UUID(),
        kind: EventKind,
        startTime: Date,
        endTime: Date? = nil,
        feedType: FeedType? = nil,
        amountML: Double? = nil,
        breastSide: Side? = nil,
        diaperType: DiaperType? = nil,
        note: String = "",
        baby: Baby? = nil
    ) {
        self.id = id
        self.kind = kind
        self.startTime = startTime
        self.endTime = endTime
        self.feedType = feedType
        self.amountML = amountML
        self.breastSide = breastSide
        self.diaperType = diaperType
        self.note = note
        self.baby = baby
    }

    var isOngoing: Bool {
        endTime == nil && (kind == .feed || kind == .sleep || kind == .pump)
    }
}
