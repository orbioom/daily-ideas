import SwiftUI

/// A unified object the UI can plot, search, and describe — star, planet, Sun, or Moon.
enum SkyObjectKind: String {
    case star = "Star"
    case planet = "Planet"
    case sun = "Sun"
    case moon = "Moon"

    var symbol: String {
        switch self {
        case .star: return "star.fill"
        case .planet: return "circle.fill"
        case .sun: return "sun.max.fill"
        case .moon: return "moon.fill"
        }
    }
}

/// A computed position of an object for a specific instant and observer.
struct SkyObject: Identifiable {
    let id: String
    let name: String
    let kind: SkyObjectKind
    let constellation: String
    let magnitude: Double
    let equatorial: EquatorialCoord
    let horizontal: HorizontalCoord
    /// Tint used to plot the object on the chart.
    let tint: Color
    /// Underlying solar body, if any (for rise/set lookups).
    let body: SolarBody?
    /// Underlying catalogue star id, if any.
    let starID: Int?
    let summary: String

    var isAboveHorizon: Bool { horizontal.isAboveHorizon }

    /// A spoken-word description of where the object is now.
    var directionPhrase: String {
        if isAboveHorizon {
            return "\(Int(horizontal.altitude.rounded()))° above the horizon, toward the \(horizontal.compass16)"
        } else {
            return "Below the horizon"
        }
    }
}

extension SkyObject {
    /// Tint colours for the planets and luminaries.
    static func tint(for body: SolarBody) -> Color {
        switch body {
        case .sun: return Color(hex: 0xFFD24A)
        case .moon: return Color(hex: 0xE8ECF5)
        case .mercury: return Color(hex: 0xC9B58A)
        case .venus: return Color(hex: 0xFFF3C4)
        case .mars: return Color(hex: 0xE2725B)
        case .jupiter: return Color(hex: 0xE3C28A)
        case .saturn: return Color(hex: 0xE6D6A8)
        case .uranus: return Color(hex: 0x8FE3E0)
        case .neptune: return Color(hex: 0x7C9CF0)
        }
    }

    static func planetSummary(_ body: SolarBody) -> String {
        switch body {
        case .sun: return "Our star — never observe it directly without certified solar protection."
        case .moon: return "Earth's only natural satellite and the brightest object in the night sky."
        case .mercury: return "The smallest planet, never far from the Sun — best near dawn or dusk."
        case .venus: return "The brightest planet, a dazzling 'morning' or 'evening star'."
        case .mars: return "The red planet, distinctly ruddy to the naked eye."
        case .jupiter: return "The largest planet; its four bright moons are visible in binoculars."
        case .saturn: return "The ringed planet — a steady golden point, glorious in a small telescope."
        case .uranus: return "A distant ice giant, just at the edge of naked-eye visibility under dark skies."
        case .neptune: return "The farthest planet, a faint blue point requiring binoculars or a telescope."
        }
    }
}
