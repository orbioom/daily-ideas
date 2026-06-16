import UIKit

/// Small wrapper around UIKit feedback generators. All calls are no-ops when
/// `enabled` is false (driven by `AppSettings.hapticsEnabled`).
enum Haptics {
    static func roll(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
    }

    static func hold(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func score(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func yahtzee(enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func win(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
