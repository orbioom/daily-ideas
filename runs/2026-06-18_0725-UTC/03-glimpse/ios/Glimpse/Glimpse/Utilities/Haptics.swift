import UIKit

/// Small haptics helper. Every call is gated by the caller passing `enabled`,
/// which is wired to `AppSettings.hapticsEnabled`.
enum Haptics {
    static func tap(_ enabled: Bool, style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
    }

    static func warning(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.warning)
    }

    static func selection(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
        gen.selectionChanged()
    }
}
