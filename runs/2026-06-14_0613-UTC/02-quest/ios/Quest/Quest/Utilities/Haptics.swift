import SwiftUI
import UIKit

/// Sparse, taste-gated haptics. All calls are no-ops when the user disables haptics
/// in Settings, so feature code can fire freely without re-checking the toggle.
enum Haptics {

    enum Kind {
        case light, medium, success, warning, selection
    }

    /// Fire a haptic if the user has them enabled.
    static func play(_ kind: Kind, enabled: Bool) {
        guard enabled else { return }
        switch kind {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
