import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Centralized, sparse haptics. All calls are gated by the user's Settings toggle,
/// read from @AppStorage("hapticsEnabled").
enum Haptics {

    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func success() {
        guard enabled else { return }
        #if canImport(UIKit)
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        #endif
    }

    static func warning() {
        guard enabled else { return }
        #if canImport(UIKit)
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
        #endif
    }

    static func light() {
        guard enabled else { return }
        #if canImport(UIKit)
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        #endif
    }
}
