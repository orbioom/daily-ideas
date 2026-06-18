import SwiftUI

/// Simulated Pro entitlement. One-time unlock persisted in UserDefaults under "isPro".
/// StoreKit-ready: replace `unlock()` with a real purchase flow.
enum ProLimits {
    /// Free users can run at most this many concurrent timers.
    static let freeTimerCap = 2
    /// Free users can save at most this many custom foods.
    static let freeCustomFoodCap = 3
}

@MainActor
final class ProStore: ObservableObject {
    private static let key = "isPro"

    /// Published so any view observing the store updates immediately on unlock.
    @Published var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: Self.key) }
    }

    init() {
        self.isPro = UserDefaults.standard.bool(forKey: Self.key)
    }

    func unlock() { isPro = true }
    func restore() { /* Simulated: nothing server-side. A real build queries StoreKit. */ }

    func timerCap() -> Int { isPro ? Int.max : ProLimits.freeTimerCap }
    func customFoodCap() -> Int { isPro ? Int.max : ProLimits.freeCustomFoodCap }
}
