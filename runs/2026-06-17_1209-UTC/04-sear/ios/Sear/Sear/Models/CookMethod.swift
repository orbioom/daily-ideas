import SwiftUI

/// How the cook is run over live fire (never sous-vide).
enum CookMethod: String, CaseIterable, Identifiable, Codable {
    case grill, smoke, roast, reverseSear
    var id: String { rawValue }

    var label: String {
        switch self {
        case .grill: return "Grill"
        case .smoke: return "Smoke"
        case .roast: return "Roast"
        case .reverseSear: return "Reverse Sear"
        }
    }

    var symbol: String {
        switch self {
        case .grill: return "flame"
        case .smoke: return "smoke"
        case .roast: return "oven"
        case .reverseSear: return "thermometer.sun"
        }
    }

    /// Whether the stall (smoking plateau) is worth watching for.
    var watchesStall: Bool {
        self == .smoke
    }

    var hue: Color {
        switch self {
        case .grill: return Color(hex: 0xE8861E)
        case .smoke: return Color(hex: 0x7C6A5C)
        case .roast: return Color(hex: 0xC97A12)
        case .reverseSear: return Color(hex: 0xD23A1E)
        }
    }
}
