import SwiftUI

enum Cuisine: String, Codable, CaseIterable, Identifiable {
    case italian = "Italian"
    case japanese = "Japanese"
    case mexican = "Mexican"
    case thai = "Thai"
    case chinese = "Chinese"
    case indian = "Indian"
    case american = "American"
    case french = "French"
    case mediterranean = "Mediterranean"
    case korean = "Korean"
    case vietnamese = "Vietnamese"
    case pizza = "Pizza"
    case burgers = "Burgers"
    case seafood = "Seafood"
    case cafe = "Cafe"
    case bakery = "Bakery"
    case bbq = "BBQ"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .italian: return "fork.knife"
        case .japanese: return "fish"
        case .mexican: return "flame"
        case .thai: return "leaf"
        case .chinese: return "takeoutbag.and.cup.and.straw"
        case .indian: return "circle.grid.cross"
        case .american: return "star"
        case .french: return "wineglass"
        case .mediterranean: return "sun.max"
        case .korean: return "flame.fill"
        case .vietnamese: return "drop"
        case .pizza: return "triangle"
        case .burgers: return "circle.hexagongrid"
        case .seafood: return "fish.fill"
        case .cafe: return "cup.and.saucer"
        case .bakery: return "birthday.cake"
        case .bbq: return "flame.circle"
        case .other: return "fork.knife.circle"
        }
    }

    /// Hue tied to each cuisine for chips/badges. Returns a dynamic color.
    var hue: Color {
        switch self {
        case .italian: return Color.dyn(0xB23A2E, 0xE07A6C)
        case .japanese: return Color.dyn(0x9A4458, 0xD98AA0)
        case .mexican: return Color.dyn(0xC9701B, 0xE6A45A)
        case .thai: return Color.dyn(0x3E8E5A, 0x73C794)
        case .chinese: return Color.dyn(0xB5302E, 0xE36F6C)
        case .indian: return Color.dyn(0xC08418, 0xE5BB57)
        case .american: return Color.dyn(0x3A6EA5, 0x7BA7D8)
        case .french: return Color.dyn(0x6C4A8C, 0xA988C9)
        case .mediterranean: return Color.dyn(0x2E8C8C, 0x6CC6C6)
        case .korean: return Color.dyn(0xA53B2A, 0xD9786A)
        case .vietnamese: return Color.dyn(0x3F8E72, 0x77C5AC)
        case .pizza: return Color.dyn(0xC23E2A, 0xE57C6A)
        case .burgers: return Color.dyn(0x8A5A2B, 0xC79361)
        case .seafood: return Color.dyn(0x2F77A8, 0x6FAAD6)
        case .cafe: return Color.dyn(0x6B4A38, 0xB28E78)
        case .bakery: return Color.dyn(0xB56A86, 0xDD9CB2)
        case .bbq: return Color.dyn(0x8A3B22, 0xC77A5E)
        case .other: return Color.dyn(0x6E5A50, 0xB29C90)
        }
    }
}
