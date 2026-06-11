import SwiftUI
import UIKit

/// Timber's visual identity: a nocturnal cabin — deep indigo nights,
/// warm lamplight amber, rounded timber-soft shapes.
enum Theme {
    static let amber = Color(red: 0.96, green: 0.69, blue: 0.30)
    static let ember = Color(red: 0.92, green: 0.45, blue: 0.27)
    static let moss = Color(red: 0.45, green: 0.78, blue: 0.55)

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.05, green: 0.06, blue: 0.12)
                        : Color(red: 0.97, green: 0.96, blue: 0.93)
    }
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.10, green: 0.12, blue: 0.20)
                        : Color.white
    }
    static func inkPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.93, green: 0.93, blue: 0.96)
                        : Color(red: 0.13, green: 0.15, blue: 0.23)
    }
    static func inkSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.62, green: 0.65, blue: 0.75)
                        : Color(red: 0.42, green: 0.44, blue: 0.52)
    }

    static func intensityColor(_ intensity: SnoreIntensity) -> Color {
        switch intensity {
        case .mild: return moss
        case .loud: return amber
        case .epic: return ember
        }
    }

    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case ..<25: return moss
        case ..<60: return amber
        default: return ember
        }
    }
}

/// Haptic helper gated by the user's Settings toggle.
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
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.06), radius: 8, y: 3)
    }
}

extension View {
    func timberCard() -> some View { modifier(CardBackground()) }
}
