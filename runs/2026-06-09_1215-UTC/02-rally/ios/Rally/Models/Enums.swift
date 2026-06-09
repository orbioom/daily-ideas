import SwiftUI

/// The racket sport a match is played in.
enum Sport: String, CaseIterable, Identifiable, Codable {
    case pickleball, tennis

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pickleball: return "Pickleball"
        case .tennis: return "Tennis"
        }
    }

    var symbol: String {
        switch self {
        case .pickleball: return "circle.grid.cross"
        case .tennis: return "tennisball"
        }
    }

    /// Common winning targets offered when creating a match.
    var pointOptions: [Int] {
        switch self {
        case .pickleball: return [11, 15, 21]
        case .tennis: return [4, 6, 7]
        }
    }

    var defaultPointsToWin: Int {
        switch self {
        case .pickleball: return 11
        case .tennis: return 6
        }
    }

    var tint: Color {
        switch self {
        case .pickleball: return Brand.magic
        case .tennis: return Brand.info
        }
    }
}

/// Whether the match is one-on-one or two-on-two.
enum MatchFormat: String, CaseIterable, Identifiable, Codable {
    case singles, doubles

    var id: String { rawValue }

    var label: String {
        switch self {
        case .singles: return "Singles"
        case .doubles: return "Doubles"
        }
    }

    var symbol: String {
        switch self {
        case .singles: return "person"
        case .doubles: return "person.2"
        }
    }

    /// Players expected on each side.
    var perSide: Int {
        switch self {
        case .singles: return 1
        case .doubles: return 2
        }
    }
}
