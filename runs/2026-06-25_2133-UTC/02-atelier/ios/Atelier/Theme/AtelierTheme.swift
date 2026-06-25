import SwiftUI

enum AtelierTheme {
    static let ink = Color(red: 0.133, green: 0.133, blue: 0.157)
    static let charcoal = Color(red: 0.231, green: 0.227, blue: 0.243)
    static let amber = Color(red: 0.937, green: 0.596, blue: 0.196)
    static let terracotta = Color(red: 0.753, green: 0.361, blue: 0.259)
    static let sage = Color(red: 0.471, green: 0.600, blue: 0.490)
    static let paper = Color(red: 0.980, green: 0.969, blue: 0.941)
    static let cream = Color(red: 0.957, green: 0.941, blue: 0.910)
}

extension ArtMedium {
    var color: Color {
        switch self {
        case .pencil:     return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .charcoal:   return Color(red: 0.3, green: 0.3, blue: 0.3)
        case .ink:        return Color(red: 0.1, green: 0.1, blue: 0.35)
        case .watercolor: return Color(red: 0.3, green: 0.6, blue: 0.85)
        case .acrylic:    return Color(red: 0.85, green: 0.35, blue: 0.35)
        case .oil:        return Color(red: 0.65, green: 0.35, blue: 0.15)
        case .gouache:    return Color(red: 0.55, green: 0.75, blue: 0.55)
        case .pastel:     return Color(red: 0.85, green: 0.65, blue: 0.75)
        case .digital:    return Color(red: 0.3, green: 0.55, blue: 0.9)
        case .mixedMedia: return AtelierTheme.amber
        }
    }
}

extension SkillStatus {
    var color: Color {
        switch self {
        case .notStarted: return .secondary
        case .learning:   return Color(red: 0.3, green: 0.6, blue: 0.85)
        case .practicing: return AtelierTheme.amber
        case .comfortable: return AtelierTheme.sage
        case .mastered:   return AtelierTheme.terracotta
        }
    }
}

extension SessionMood {
    var color: Color {
        switch self {
        case .excellent: return AtelierTheme.terracotta
        case .good:      return AtelierTheme.amber
        case .okay:      return AtelierTheme.sage
        case .frustrated: return Color(red: 0.8, green: 0.45, blue: 0.2)
        case .blocked:   return .secondary
        }
    }
}

struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct AtelierRatingView: View {
    let rating: Int
    let size: CGFloat

    init(rating: Int, size: CGFloat = 14) {
        self.rating = rating; self.size = size
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(i <= rating ? AtelierTheme.amber : Color.secondary)
            }
        }
    }
}

struct MediumBadge: View {
    let medium: ArtMedium

    var body: some View {
        Label(medium.rawValue, systemImage: medium.sfSymbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(medium.color.opacity(0.15))
            .foregroundStyle(medium.color)
            .clipShape(Capsule())
    }
}
