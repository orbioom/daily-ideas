import UIKit

/// Sparse, tasteful haptics — gated by the Settings toggle (read from @AppStorage).
enum Haptics {

    private static var enabled: Bool {
        // Default ON, matching the SettingsView default.
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func success() {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }

    static func tap() {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    static func selection() {
        guard enabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }
}
