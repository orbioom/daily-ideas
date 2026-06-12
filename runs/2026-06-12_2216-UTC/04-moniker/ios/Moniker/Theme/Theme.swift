import SwiftUI
import UIKit

/// Moniker design language: a warm nursery at dusk — blush rose, soft cream,
/// rounded type, paper-card stacks with gentle tilts.
enum MonikerTheme {
    static let rose = Color(red: 0.91, green: 0.56, blue: 0.71)
    static let roseDeep = Color(red: 0.72, green: 0.32, blue: 0.48)
    static let sky = Color(red: 0.45, green: 0.62, blue: 0.86)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.92)

    static func genderColor(_ gender: NameGender) -> Color {
        switch gender {
        case .girl: return rose
        case .boy: return sky
        case .unisex: return Color(red: 0.55, green: 0.72, blue: 0.55)
        }
    }
}

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func like() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func match() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension View {
    func monikerPanel() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct StyleChip: View {
    let style: NameStyle
    var selected: Bool = false

    var body: some View {
        Text(style.displayName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(selected ? MonikerTheme.rose.opacity(0.25) : Color(.tertiarySystemFill))
            )
            .overlay(
                Capsule().strokeBorder(selected ? MonikerTheme.roseDeep : Color.clear, lineWidth: 1)
            )
    }
}
