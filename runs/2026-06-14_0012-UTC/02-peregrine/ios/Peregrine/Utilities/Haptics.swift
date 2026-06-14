import UIKit

/// Thin wrapper over UIKit haptics, gated by the user's Settings toggle. Sparse
/// by design: correct/incorrect feedback and major milestones only.
enum Haptics {
    /// Mirrors the @AppStorage("hapticsEnabled") flag; read once per fire.
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func success() {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func error() {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.error)
    }

    static func tap() {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func celebrate() {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }
}
