import SwiftUI

/// Simulated Pro entitlement. Persisted in @AppStorage. No real StoreKit
/// here — this is StoreKit-ready scaffolding for a one-time unlock.
@MainActor
final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false

    /// Free-tier limits. The free core is fully usable; Pro lifts caps and
    /// unlocks export, custom markers and trend insights.
    static let freeTrackedMarkerCap = 8
    static let freePanelCap = 2

    static let priceLabel = "$14.99 one-time"

    func unlock() { isPro = true }
    func restore() { isPro = true } // simulated restore
}
