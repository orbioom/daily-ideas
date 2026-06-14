import Foundation

/// Outcome of a finished game, stored as a raw string in SwiftData.
enum GameResultKind: String, Codable, CaseIterable, Identifiable {
    case win
    case loss
    case draw
    case inProgress

    var id: String { rawValue }

    var label: String {
        switch self {
        case .win: return "Win"
        case .loss: return "Loss"
        case .draw: return "Draw"
        case .inProgress: return "In progress"
        }
    }

    var symbol: String {
        switch self {
        case .win: return "trophy.fill"
        case .loss: return "flag.fill"
        case .draw: return "equal.circle.fill"
        case .inProgress: return "hourglass"
        }
    }
}

/// Which side the human plays.
enum HumanSide: String, Codable, CaseIterable, Identifiable {
    case white
    case black

    var id: String { rawValue }
    var color: PieceColor { self == .white ? .white : .black }
    var label: String { self == .white ? "White" : "Black" }
}
