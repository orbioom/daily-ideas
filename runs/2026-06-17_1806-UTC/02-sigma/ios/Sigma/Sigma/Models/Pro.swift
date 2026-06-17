import SwiftUI

/// Pro entitlement and its limits. The unlock is simulated (StoreKit-ready):
/// a single non-consumable would set `isPro` in a real build.
@MainActor final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false {
        willSet { objectWillChange.send() }
    }

    static let price = "$2.99"

    /// Free tier caps the saved history at this many entries (oldest pruned).
    static let freeHistoryCap = 50

    /// Unlocks the Pro tier (simulated purchase).
    func unlock() { isPro = true }

    /// Restores a previous purchase (simulated).
    func restore() { isPro = true }
}
