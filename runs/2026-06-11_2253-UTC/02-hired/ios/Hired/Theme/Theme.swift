import SwiftUI
import UIKit

/// Hired's identity: an editorial broadsheet — ivory paper, ink type with
/// serif display headers, one confident electric blue, stage-colored chips.
enum Theme {
    static let blue = Color(red: 0.18, green: 0.40, blue: 0.96)

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10)
                        : Color(red: 0.96, green: 0.95, blue: 0.91)
    }
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.13, green: 0.13, blue: 0.16) : .white
    }
    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.92, green: 0.92, blue: 0.94)
                        : Color(red: 0.11, green: 0.12, blue: 0.16)
    }
    static func inkSoft(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.62, green: 0.63, blue: 0.68)
                        : Color(red: 0.44, green: 0.45, blue: 0.50)
    }

    static func stageColor(_ stage: Stage) -> Color {
        switch stage {
        case .wishlist: return Color(red: 0.58, green: 0.55, blue: 0.85)
        case .applied: return blue
        case .screening: return Color(red: 0.95, green: 0.62, blue: 0.22)
        case .interview: return Color(red: 0.91, green: 0.42, blue: 0.55)
        case .offer: return Color(red: 0.22, green: 0.68, blue: 0.48)
        case .accepted: return Color(red: 0.13, green: 0.55, blue: 0.36)
        case .rejected: return Color(red: 0.65, green: 0.28, blue: 0.25)
        case .ghosted: return Color(red: 0.50, green: 0.52, blue: 0.58)
        case .withdrawn: return Color(red: 0.55, green: 0.48, blue: 0.40)
        }
    }

    /// Serif display font for the editorial feel.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
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
            .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.05), radius: 6, y: 2)
    }
}

extension View {
    func hiredCard() -> some View { modifier(CardBackground()) }
}

struct StageChip: View {
    let stage: Stage
    var body: some View {
        Label(stage.label, systemImage: stage.icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.stageColor(stage).opacity(0.16), in: Capsule())
            .foregroundStyle(Theme.stageColor(stage))
    }
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
                .foregroundStyle(Theme.blue)
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
