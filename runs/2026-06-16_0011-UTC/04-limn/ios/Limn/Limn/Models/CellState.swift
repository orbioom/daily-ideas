import Foundation

/// The three states a single board cell can be in.
/// `unknown` = untouched, `filled` = player painted it, `crossed` = player marked it definitely empty.
enum CellState: Int, Codable, Equatable {
    case unknown = 0
    case filled = 1
    case crossed = 2

    /// VoiceOver-readable description of the cell's current mark.
    var accessibilityValue: String {
        switch self {
        case .unknown: return "blank"
        case .filled: return "filled"
        case .crossed: return "crossed out"
        }
    }
}
