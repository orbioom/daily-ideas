import SwiftUI
import UIKit

/// Podium's identity: a dark stage with a violet spotlight — deep charcoal,
/// stage-light violet, warm cream text, confident rounded type.
enum Theme {
    static let violet = Color(red: 0.56, green: 0.42, blue: 0.96)
    static let gold = Color(red: 0.95, green: 0.78, blue: 0.34)
    static let green = Color(red: 0.36, green: 0.78, blue: 0.56)
    static let red = Color(red: 0.92, green: 0.42, blue: 0.40)

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.07, green: 0.06, blue: 0.10)
                        : Color(red: 0.97, green: 0.96, blue: 0.99)
    }
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.12, green: 0.11, blue: 0.17) : .white
    }
    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.95, green: 0.94, blue: 0.91)
                        : Color(red: 0.14, green: 0.12, blue: 0.20)
    }
    static func inkSoft(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.64, green: 0.62, blue: 0.72)
                        : Color(red: 0.45, green: 0.43, blue: 0.53)
    }

    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 70...: return green
        case 45..<70: return gold
        default: return red
        }
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
            .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.06), radius: 8, y: 3)
    }
}

extension View {
    func podiumCard() -> some View { modifier(CardBackground()) }
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
                .foregroundStyle(Theme.violet)
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

struct ScoreBadge: View {
    let score: Int
    var size: CGFloat = 52
    var body: some View {
        Text("\(score)")
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .monospacedDigit()
            .frame(width: size, height: size)
            .background(Theme.scoreColor(score).opacity(0.16), in: Circle())
            .overlay(Circle().stroke(Theme.scoreColor(score), lineWidth: 2))
            .foregroundStyle(Theme.scoreColor(score))
            .accessibilityLabel("Score \(score) out of 100")
    }
}
