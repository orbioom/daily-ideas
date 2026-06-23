import UIKit

/// Thin wrapper over UIKit feedback generators, globally gated by a settings flag.
@MainActor
final class Haptics {
    static let shared = Haptics()
    private init() {}

    /// Mirror of the user's Settings toggle. Updated by the app when settings load.
    var enabled: Bool = true

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        guard enabled else { return }
        impactLight.prepare()
        impactMedium.prepare()
        impactSoft.prepare()
    }

    func phaseChange() {
        guard enabled else { return }
        impactSoft.impactOccurred(intensity: 0.7)
    }

    func tick() {
        guard enabled else { return }
        impactLight.impactOccurred(intensity: 0.4)
    }

    func tap() {
        guard enabled else { return }
        impactLight.impactOccurred()
    }

    func success() {
        guard enabled else { return }
        notification.notificationOccurred(.success)
    }

    func warning() {
        guard enabled else { return }
        notification.notificationOccurred(.warning)
    }
}
