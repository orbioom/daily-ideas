import SwiftUI

enum Cuisine: String, Codable, CaseIterable, Identifiable {
    case italian = "Italian"
    case mexican = "Mexican"
    case american = "American"
    case asian = "Asian"
    case indian = "Indian"
    case mediterranean = "Mediterranean"
    case french = "French"
    case middleEastern = "Middle Eastern"
    case breakfast = "Breakfast"
    case dessert = "Dessert"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .italian: return "fork.knife"
        case .mexican: return "flame"
        case .american: return "star"
        case .asian: return "takeoutbag.and.cup.and.straw"
        case .indian: return "circle.grid.cross"
        case .mediterranean: return "sun.max"
        case .french: return "wineglass"
        case .middleEastern: return "moon.stars"
        case .breakfast: return "cup.and.saucer"
        case .dessert: return "birthday.cake"
        case .other: return "fork.knife.circle"
        }
    }

    var hue: Color {
        switch self {
        case .italian: return Color.dyn(0xB23A2E, 0xE07A6C)
        case .mexican: return Color.dyn(0xC9701B, 0xE6A45A)
        case .american: return Color.dyn(0x3A6EA5, 0x7BA7D8)
        case .asian: return Color.dyn(0xA53B2A, 0xD9786A)
        case .indian: return Color.dyn(0xC08418, 0xE5BB57)
        case .mediterranean: return Color.dyn(0x2E8C8C, 0x6CC6C6)
        case .french: return Color.dyn(0x6C4A8C, 0xA988C9)
        case .middleEastern: return Color.dyn(0x3F8E72, 0x77C5AC)
        case .breakfast: return Color.dyn(0x6B4A38, 0xB28E78)
        case .dessert: return Color.dyn(0xB56A86, 0xDD9CB2)
        case .other: return Color.dyn(0x6E5A50, 0xB29C90)
        }
    }
}
