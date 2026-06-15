import SwiftUI

/// The paper style drawn behind the canvas. Stored as a raw String in SwiftData.
enum PaperTemplate: String, CaseIterable, Identifiable, Codable {
    case blank
    case ruled
    case grid
    case dotted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blank: return "Blank"
        case .ruled: return "Ruled"
        case .grid: return "Grid"
        case .dotted: return "Dotted"
        }
    }

    var systemImage: String {
        switch self {
        case .blank: return "rectangle"
        case .ruled: return "list.bullet.rectangle"
        case .grid: return "grid"
        case .dotted: return "circle.grid.3x3"
        }
    }

    /// Grid and dotted templates are reserved for Quill Pro.
    var requiresPro: Bool {
        switch self {
        case .blank, .ruled: return false
        case .grid, .dotted: return true
        }
    }

    /// Templates available to the user given the current Pro state.
    static func available(isPro: Bool) -> [PaperTemplate] {
        allCases.filter { isPro || !$0.requiresPro }
    }
}
