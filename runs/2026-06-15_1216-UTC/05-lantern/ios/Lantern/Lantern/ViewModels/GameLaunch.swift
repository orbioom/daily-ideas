import Foundation

/// Describes how a game should be started, used as a NavigationStack route.
struct GameLaunch: Hashable {
    enum Source: Hashable {
        case fresh(LayoutKind)
        case resume                 // resume the persisted SavedGame
        case daily(dateKey: String, layout: LayoutKind)
    }
    let source: Source
}
