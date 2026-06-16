import SwiftUI
import UIKit

/// Small wrapper around UIKit feedback generators. All calls are gated by the
/// caller passing `enabled` (driven by `AppSettings.hapticsEnabled`).
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
        gen.selectionChanged()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType, enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }
}
