import SwiftUI

enum DominoTheme {
    // MARK: - Core Colors
    static let mahogany = Color(red: 0.290, green: 0.173, blue: 0.090)   // #4A2C17
    static let ivory = Color(red: 0.961, green: 0.941, blue: 0.878)      // #F5F0E0
    static let gold = Color(red: 0.784, green: 0.663, blue: 0.431)       // #C8A96E
    static let darkPip = Color(red: 0.10, green: 0.07, blue: 0.05)       // near-black for pips
    static let chainHighlight = Color(red: 0.2, green: 0.5, blue: 0.9)   // blue for open ends
    static let mahoganyDark = Color(red: 0.18, green: 0.10, blue: 0.05)  // darker mahogany for depth

    // MARK: - Semantic
    static let background = mahogany
    static let tileBackground = ivory
    static let accent = gold
    static let pipColor = darkPip
    static let openEndIndicator = chainHighlight

    // MARK: - Tile Styles
    enum TileStyle: String, CaseIterable {
        case classic
        case modern
        case dark

        var tileColor: Color {
            switch self {
            case .classic: return ivory
            case .modern: return Color(red: 0.95, green: 0.95, blue: 0.95)
            case .dark: return Color(red: 0.15, green: 0.12, blue: 0.10)
            }
        }

        var pipColor: Color {
            switch self {
            case .classic: return darkPip
            case .modern: return Color(red: 0.15, green: 0.15, blue: 0.15)
            case .dark: return Color(red: 0.90, green: 0.85, blue: 0.75)
            }
        }

        var dividerColor: Color {
            switch self {
            case .classic: return Color(red: 0.3, green: 0.2, blue: 0.1)
            case .modern: return Color(red: 0.5, green: 0.5, blue: 0.5)
            case .dark: return Color(red: 0.6, green: 0.5, blue: 0.4)
            }
        }

        var displayName: String { rawValue.capitalized }
    }

    // MARK: - Typography
    static let titleFont = Font.custom("Georgia", size: 32).weight(.bold)
    static let subtitleFont = Font.custom("Georgia", size: 20)
    static let bodyFont = Font.system(.body, design: .serif)
    static let captionFont = Font.system(.caption, design: .serif)
    static let scoreFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let pipCountFont = Font.system(size: 11, weight: .semibold, design: .rounded)

    // MARK: - Shadows
    static let tileShadow = Shadow(color: .black.opacity(0.4), radius: 4, x: 2, y: 2)
    static let cardShadow = Shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

    // MARK: - Dimensions
    static let tileShortSide: CGFloat = 40
    static let tileLongSide: CGFloat = 80
    static let tileCornerRadius: CGFloat = 6
    static let pipRadius: CGFloat = 4
    static let boardSpacing: CGFloat = 4
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func dominoTileShadow() -> some View {
        self.shadow(
            color: DominoTheme.tileShadow.color,
            radius: DominoTheme.tileShadow.radius,
            x: DominoTheme.tileShadow.x,
            y: DominoTheme.tileShadow.y
        )
    }

    func dominoCardShadow() -> some View {
        self.shadow(
            color: DominoTheme.cardShadow.color,
            radius: DominoTheme.cardShadow.radius,
            x: DominoTheme.cardShadow.x,
            y: DominoTheme.cardShadow.y
        )
    }
}
