import SwiftUI
import UIKit

/// Flipside's identity: a sunny thrift haul — warm cream, kraft-paper cards,
/// tangerine price-tag accents, teal for profit.
enum Theme {
    static let tangerine = Color(red: 0.94, green: 0.41, blue: 0.24)
    static let teal = Color(red: 0.10, green: 0.59, blue: 0.55)
    static let mustard = Color(red: 0.89, green: 0.69, blue: 0.25)

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.10, green: 0.08, blue: 0.07)
                        : Color(red: 0.99, green: 0.96, blue: 0.90)
    }
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.16, green: 0.13, blue: 0.11)
                        : Color.white
    }
    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.95, green: 0.92, blue: 0.88)
                        : Color(red: 0.20, green: 0.15, blue: 0.10)
    }
    static func inkSoft(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.68, green: 0.63, blue: 0.58)
                        : Color(red: 0.48, green: 0.43, blue: 0.38)
    }

    static func statusColor(_ status: ItemStatus) -> Color {
        switch status {
        case .sourced: return mustard
        case .listed: return tangerine
        case .sold: return teal
        }
    }

    static func profitColor(_ value: Double) -> Color {
        value >= 0 ? teal : Color(red: 0.80, green: 0.30, blue: 0.25)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
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
            .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.05), radius: 6, y: 2)
    }
}

extension View {
    func flipCard() -> some View { modifier(CardBackground()) }
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
                .foregroundStyle(Theme.tangerine)
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

struct StatusChip: View {
    let status: ItemStatus
    var body: some View {
        Label(status.label, systemImage: status.icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.statusColor(status).opacity(0.16), in: Capsule())
            .foregroundStyle(Theme.statusColor(status))
    }
}
