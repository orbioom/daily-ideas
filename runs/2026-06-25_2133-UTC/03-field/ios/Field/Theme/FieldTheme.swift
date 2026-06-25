import SwiftUI

enum FieldTheme {
    static let fern = Color(red: 0.200, green: 0.443, blue: 0.278)
    static let moss = Color(red: 0.290, green: 0.561, blue: 0.322)
    static let bark = Color(red: 0.369, green: 0.255, blue: 0.180)
    static let sky = Color(red: 0.306, green: 0.620, blue: 0.835)
    static let soil = Color(red: 0.576, green: 0.408, blue: 0.239)
    static let lichen = Color(red: 0.624, green: 0.714, blue: 0.498)
    static let fog = Color(red: 0.878, green: 0.898, blue: 0.878)
}

extension SpeciesClass {
    var color: Color {
        switch self {
        case .bird:      return FieldTheme.sky
        case .mammal:    return FieldTheme.bark
        case .reptile:   return Color(red: 0.6, green: 0.65, blue: 0.2)
        case .amphibian: return Color(red: 0.2, green: 0.7, blue: 0.55)
        case .insect:    return Color(red: 0.8, green: 0.55, blue: 0.1)
        case .arachnid:  return Color(red: 0.55, green: 0.15, blue: 0.15)
        case .plant:     return FieldTheme.fern
        case .tree:      return FieldTheme.moss
        case .mushroom:  return FieldTheme.soil
        case .fish:      return Color(red: 0.2, green: 0.55, blue: 0.85)
        case .other:     return Color.secondary
        }
    }
}

struct SpeciesClassBadge: View {
    let speciesClass: SpeciesClass

    var body: some View {
        Label(speciesClass.rawValue, systemImage: speciesClass.sfSymbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(speciesClass.color.opacity(0.15))
            .foregroundStyle(speciesClass.color)
            .clipShape(Capsule())
    }
}

struct LiferBadge: View {
    var body: some View {
        Text("LIFER")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.yellow.opacity(0.2))
            .foregroundStyle(Color.yellow)
            .clipShape(Capsule())
    }
}

struct FieldHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}
