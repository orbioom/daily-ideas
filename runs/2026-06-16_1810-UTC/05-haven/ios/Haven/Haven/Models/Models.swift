import Foundation
import SwiftData

// MARK: - Trigger

/// A thing that can precede a hard moment. Many-to-many with PanicEpisode.
@Model
final class Trigger {
    @Attribute(.unique) var id: UUID
    var name: String
    var isCustom: Bool

    /// Inverse side of the many-to-many. Episodes that reference this trigger.
    @Relationship(inverse: \PanicEpisode.triggers)
    var episodes: [PanicEpisode]

    init(id: UUID = UUID(), name: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.isCustom = isCustom
        self.episodes = []
    }
}

// MARK: - PanicEpisode

/// A logged hard moment / panic episode.
@Model
final class PanicEpisode {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var durationMinutes: Int?
    var intensityBefore: Int          // 0–10
    var intensityAfter: Int?          // 0–10
    var context: String               // home/work/public/transit/home-alone/other
    var note: String

    /// Owning side of the many-to-many to Trigger.
    var triggers: [Trigger]

    /// Names of coping tools that helped (kept as strings so tools can be deleted safely).
    var helpedBy: [String]

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        durationMinutes: Int? = nil,
        intensityBefore: Int = 5,
        intensityAfter: Int? = nil,
        context: String = EpisodeContext.home.rawValue,
        note: String = "",
        triggers: [Trigger] = [],
        helpedBy: [String] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.durationMinutes = durationMinutes
        self.intensityBefore = intensityBefore.clamped(to: 0...10)
        self.intensityAfter = intensityAfter.map { $0.clamped(to: 0...10) }
        self.context = context
        self.note = note
        self.triggers = triggers
        self.helpedBy = helpedBy
    }

    /// Intensity drop (before − after), if an "after" was recorded.
    var intensityDrop: Int? {
        guard let after = intensityAfter else { return nil }
        return intensityBefore - after
    }
}

// MARK: - CopingItem

/// A coping statement, action, or contact prompt in the Toolbox.
@Model
final class CopingItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var kind: String          // statement / action / contact
    var isCustom: Bool
    var sortOrder: Int
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        kind: CopingKind = .statement,
        isCustom: Bool = false,
        sortOrder: Int = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.kind = kind.rawValue
        self.isCustom = isCustom
        self.sortOrder = sortOrder
        self.isFavorite = isFavorite
    }

    var copingKind: CopingKind { CopingKind(rawValue: kind) ?? .statement }
}

// MARK: - ReassuranceCard

/// A calm reassurance line shown in the swipeable card deck.
@Model
final class ReassuranceCard {
    @Attribute(.unique) var id: UUID
    var text: String
    var isCustom: Bool

    init(id: UUID = UUID(), text: String, isCustom: Bool = false) {
        self.id = id
        self.text = text
        self.isCustom = isCustom
    }
}

// MARK: - Supporting enums

enum CopingKind: String, CaseIterable, Identifiable {
    case statement, action, contact
    var id: String { rawValue }

    var label: String {
        switch self {
        case .statement: return "Reminder"
        case .action: return "Action"
        case .contact: return "Reach out"
        }
    }

    var systemImage: String {
        switch self {
        case .statement: return "quote.bubble"
        case .action: return "hand.raised.fingers.spread"
        case .contact: return "phone.bubble"
        }
    }
}

enum EpisodeContext: String, CaseIterable, Identifiable {
    case home, work, publicPlace = "public", transit, homeAlone = "home-alone", other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        case .publicPlace: return "Out in public"
        case .transit: return "Travelling"
        case .homeAlone: return "Home alone"
        case .other: return "Somewhere else"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .work: return "briefcase"
        case .publicPlace: return "figure.walk"
        case .transit: return "tram"
        case .homeAlone: return "moon.stars"
        case .other: return "mappin.and.ellipse"
        }
    }

    static func from(_ raw: String) -> EpisodeContext {
        EpisodeContext(rawValue: raw) ?? .other
    }
}

// MARK: - Small numeric helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
