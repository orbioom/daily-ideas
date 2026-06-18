import Foundation

/// A request to start (or resume) a specific game, carried via navigation.
struct GameRequest: Hashable {
    let layout: BoardLayout
    let dealNumber: Int
    let isDaily: Bool
    /// When true, resume from the persisted SavedGame instead of dealing fresh.
    let resume: Bool

    static func new(_ layout: BoardLayout, dealNumber: Int, isDaily: Bool) -> GameRequest {
        GameRequest(layout: layout, dealNumber: dealNumber, isDaily: isDaily, resume: false)
    }

    static func resumeSaved(_ layout: BoardLayout, dealNumber: Int, isDaily: Bool) -> GameRequest {
        GameRequest(layout: layout, dealNumber: dealNumber, isDaily: isDaily, resume: true)
    }
}

/// Routes pushed onto a NavigationStack from the Home tab.
enum HomeRoute: Hashable {
    case newGame
    case howToPlay
    case game(GameRequest)
}
