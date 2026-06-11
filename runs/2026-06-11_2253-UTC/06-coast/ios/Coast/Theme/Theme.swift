import SwiftUI
import UIKit

/// Coast's identity: a calm ocean horizon — deep teal sea, sun-gold accents,
/// foam highlights. Patient, optimistic, financial-but-not-corporate.
enum Theme {
    static let teal = Color(red: 0.09, green: 0.66, blue: 0.60)
    static let deepSea = Color(red: 0.05, green: 0.36, blue: 0.42)
    static let sun = Color(red: 0.97, green: 0.78, blue: 0.36)
    static let coral = Color(red: 0.95, green: 0.51, blue: 0.40)

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.04, green: 0.09, blue: 0.11)
                        : Color(red: 0.95, green: 0.98, blue: 0.98)
    }
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.08, green: 0.15, blue: 0.17) : .white
    }
    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.92, green: 0.96, blue: 0.96)
                        : Color(red: 0.07, green: 0.18, blue: 0.21)
    }
    static func inkSoft(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.60, green: 0.70, blue: 0.72)
                        : Color(red: 0.40, green: 0.50, blue: 0.52)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

enum Haptics {
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }
    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.05), radius: 8, y: 3)
    }
}

extension View {
    func coastCard() -> some View { modifier(CardBackground()) }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Theme.teal)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.display(20))
                .foregroundStyle(Theme.ink(scheme))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
    }
}
