import SwiftUI
import UIKit

/// Moniker's identity: a soft nursery at golden hour — blush, sky, butter
/// pastels with deep plum ink and playful rounded type.
enum Theme {
    static let blush = Color(red: 0.93, green: 0.42, blue: 0.61)
    static let sky = Color(red: 0.45, green: 0.62, blue: 0.94)
    static let butter = Color(red: 0.96, green: 0.78, blue: 0.35)
    static let mint = Color(red: 0.42, green: 0.77, blue: 0.62)

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.11, green: 0.08, blue: 0.11)
                        : Color(red: 1.0, green: 0.96, blue: 0.96)
    }
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.17, green: 0.13, blue: 0.17) : .white
    }
    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.96, green: 0.93, blue: 0.95)
                        : Color(red: 0.25, green: 0.14, blue: 0.24)
    }
    static func inkSoft(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.70, green: 0.64, blue: 0.70)
                        : Color(red: 0.52, green: 0.44, blue: 0.52)
    }

    static func genderColor(_ gender: NameGender) -> Color {
        switch gender {
        case .girl: return blush
        case .boy: return sky
        case .neutral: return mint
        }
    }

    static func partnerColor(_ partner: Partner) -> Color {
        partner == .a ? blush : sky
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
    static func match() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.06), radius: 8, y: 3)
    }
}

extension View {
    func monikerCard() -> some View { modifier(CardBackground()) }
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
                .foregroundStyle(Theme.blush)
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

/// Reads the configured partner display names from UserDefaults.
enum PartnerNames {
    static func name(_ partner: Partner) -> String {
        let key = partner == .a ? "partnerAName" : "partnerBName"
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        return raw.isEmpty ? (partner == .a ? "Partner A" : "Partner B") : raw
    }
}
