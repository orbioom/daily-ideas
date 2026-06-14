import Foundation

enum CellState: Int, Codable {
    case hidden
    case revealed
    case flagged
    case questioned
}

/// A single board cell. Codable so the in-progress game can be persisted as JSON.
struct Cell: Codable, Equatable {
    var hasMine: Bool = false
    var adjacent: Int = 0
    var state: CellState = .hidden
    /// Set during a loss reveal to mark a flag that was placed on a non-mine.
    var wrongFlag: Bool = false
    /// Set during a loss reveal on the specific mine the player detonated.
    var detonated: Bool = false
}
