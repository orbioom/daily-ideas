import UIKit

/// Thin haptics helper. All calls are gated by the caller passing `enabled`,
/// which reflects `AppSettings.hapticsEnabled`.
enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    static func medium(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
    }

    static func rigid(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.impactOccurred()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func warning(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }
}
