import SwiftUI
import UIKit

/// Glyph design language: a precision instrument — near-black panels,
/// mint signal-green, monospaced payloads, hard grids softened by large radii.
enum GlyphTheme {
    static let mint = Color(red: 0.33, green: 0.88, blue: 0.65)

    static let presetForegrounds: [String] = [
        "111318", "0B5A41", "1D3F8F", "6A1F8F", "8F1D3A", "8A5A0B",
    ]
    static let presetBackgrounds: [String] = [
        "FFFFFF", "F4F1E8", "E8F4EE", "E9EEFB", "F7E9F2", "FBF3E2",
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
    func glyphPanel() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
