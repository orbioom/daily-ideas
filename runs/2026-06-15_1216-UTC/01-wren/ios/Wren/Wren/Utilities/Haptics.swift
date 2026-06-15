import UIKit

/// Sparse, intentional haptics. Always gated by the user's Settings toggle,
/// which is passed in by callers so this stays a pure helper.
enum Haptics {
    enum Kind {
        case light, soft, success, warning
    }

    static func play(_ kind: Kind, enabled: Bool) {
        guard enabled else { return }
        switch kind {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
}
