import Foundation
import SwiftData

/// A managed gym or crag. Climbs and sessions reference a location so analytics
/// and browsing can group by where you climbed.
@Model
final class Location {
    var id: UUID
    var name: String
    /// Raw value of `LocationKind` for tolerant decoding.
    var kindRaw: String
    var createdAt: Date

    /// Climbs logged at this location (cleared, not deleted, if the location goes away).
    @Relationship(inverse: \Climb.location)
    var climbs: [Climb]

    /// Sessions held at this location.
    @Relationship(inverse: \Session.location)
    var sessions: [Session]

    init(id: UUID = UUID(),
         name: String,
         kind: LocationKind = .gym,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.createdAt = createdAt
        self.climbs = []
        self.sessions = []
    }

    /// Tolerant accessor — unknown raw values fall back to `.gym`.
    var kind: LocationKind {
        get { LocationKind(rawValue: kindRaw) ?? .gym }
        set { kindRaw = newValue.rawValue }
    }
}

/// Whether a location is an indoor gym or an outdoor crag.
enum LocationKind: String, CaseIterable, Identifiable, Codable {
    case gym
    case crag

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gym:  return "Gym"
        case .crag: return "Crag"
        }
    }

    var symbol: String {
        switch self {
        case .gym:  return "building.2"
        case .crag: return "mountain.2"
        }
    }
}
