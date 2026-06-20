import SwiftUI

enum CardTheme: String, CaseIterable, Codable, Identifiable {
    case animals, space, food, nature, classic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .animals: return "Animals"
        case .space: return "Space"
        case .food: return "Food"
        case .nature: return "Nature"
        case .classic: return "Classic"
        }
    }

    var isPro: Bool {
        self == .nature || self == .classic
    }

    var symbols: [String] {
        switch self {
        case .animals:
            return ["🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🦄","🐧","🦋"]
        case .space:
            return ["🌍","🌙","⭐","🌟","💫","☄️","🚀","🛸","🌌","🪐","🌠","⚡","🌈","🔭","🌞","🌑","🛰️","🌀"]
        case .food:
            return ["🍕","🍔","🌮","🍜","🍣","🍩","🍪","🎂","🍰","🍦","🍇","🍓","🍌","🍋","🥑","🥝","🍑","🌽"]
        case .nature:
            return ["🌸","🌺","🌻","🌷","🍀","🌿","🌱","🍁","🍂","🌾","🌊","🏔️","🌋","🏝️","🌅","🌄","🌈","⛅"]
        case .classic:
            return ["star","heart","circle","square","triangle","diamond","moon","sun.max","bolt","cloud","flame","leaf","drop","snowflake","music.note","camera","bell","house"]
        }
    }

    var accentColor: Color {
        switch self {
        case .animals: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .space: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .food: return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .nature: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .classic: return Color(red: 1.0, green: 0.42, blue: 0.42)
        }
    }

    var cardBackColor: Color {
        switch self {
        case .animals: return Color(red: 0.22, green: 0.28, blue: 0.55)
        case .space: return Color(red: 0.1, green: 0.1, blue: 0.35)
        case .food: return Color(red: 0.35, green: 0.15, blue: 0.25)
        case .nature: return Color(red: 0.1, green: 0.28, blue: 0.15)
        case .classic: return Color(red: 0.176, green: 0.169, blue: 0.412)
        }
    }

    var previewEmojis: [String] {
        switch self {
        case .animals: return ["🐶","🐱","🦊"]
        case .space: return ["🚀","🪐","⭐"]
        case .food: return ["🍕","🍩","🍣"]
        case .nature: return ["🌸","🍀","🌊"]
        case .classic: return ["star","heart","moon"]
        }
    }
}
