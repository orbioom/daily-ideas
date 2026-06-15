import UIKit

/// Sparse, centralized haptics. All calls are gated by the user's setting via
/// `AppSettings.hapticsEnabled` at the call site.
enum Haptics {
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }

    static func selection() {
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }
}
