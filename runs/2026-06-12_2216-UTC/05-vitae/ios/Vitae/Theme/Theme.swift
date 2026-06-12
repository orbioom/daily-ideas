import SwiftUI
import UIKit

/// Vitae design language: a stationer's desk — ivory paper, navy ink,
/// confident blue accent, generous whitespace, document-first layouts.
enum VitaeTheme {
    static let blue = Color(red: 0.18, green: 0.42, blue: 0.85)

    static let accentChoices: [String] = [
        "2F6BD8", "184A3C", "7A2740", "5B3A8E", "8A5A0B", "16323F",
    ]
}

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

extension View {
    func vitaePanel() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
