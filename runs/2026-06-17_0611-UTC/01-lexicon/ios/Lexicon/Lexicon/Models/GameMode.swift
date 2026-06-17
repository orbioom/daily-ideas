import Foundation

/// Whether a game is the calendar daily puzzle, an archive (past-date) puzzle,
/// or a free-form practice game.
enum GameMode: String, Codable, CaseIterable {
    case daily
    case archive
    case practice

    var title: String {
        switch self {
        case .daily: return "Daily"
        case .archive: return "Archive"
        case .practice: return "Practice"
        }
    }
}

/// The lifecycle of a single game.
enum GameStatus: String, Codable {
    case playing
    case won
    case lost

    var isFinished: Bool { self != .playing }
}
