import SwiftUI

enum SleeveTheme {
    static let darkBg      = Color(red: 0.08, green: 0.06, blue: 0.14)
    static let accent      = Color(red: 0.60, green: 0.40, blue: 0.95)
    static let cardBg      = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let silver      = Color(red: 0.75, green: 0.75, blue: 0.80)
    static let subtleText  = Color.white.opacity(0.5)
    static let gold        = Color(red: 0.95, green: 0.80, blue: 0.30)

    static func rarityColor(_ rarity: CardRarity) -> Color {
        switch rarity {
        case .common:    return .gray
        case .uncommon:  return silver
        case .rare:      return gold
        case .ultraRare: return accent
        case .secret:    return .cyan
        }
    }

    static func rarityColorFromString(_ rarity: String) -> Color {
        if let r = CardRarity(rawValue: rarity) {
            return rarityColor(r)
        }
        return .gray
    }
}

// MARK: - View Modifiers

extension View {
    func sleeveBackground() -> some View {
        self.background(SleeveTheme.darkBg.ignoresSafeArea())
    }

    func sleeveSectionHeader() -> some View {
        self
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(SleeveTheme.subtleText)
            .textCase(.uppercase)
            .tracking(1)
    }
}

// MARK: - Card Cell Style

struct CardCellBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(SleeveTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardCellBackground() -> some View {
        self.modifier(CardCellBackground())
    }
}
