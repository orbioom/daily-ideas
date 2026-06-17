import SwiftUI
import Observation

/// Simulated one-time Pro unlock. StoreKit-ready in spirit; no real purchase calls.
@Observable
final class ProStore {
    private let defaults: UserDefaults
    /// The free tier allows this many active goals.
    static let freeGoalLimit = 3
    static let price = "$4.99"

    var isPro: Bool {
        didSet { defaults.set(isPro, forKey: Self.key) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isPro = defaults.bool(forKey: Self.key)
    }

    /// Simulated purchase / restore.
    func unlock() { isPro = true }

    /// For demos only — relock to preview the free experience again.
    func relock() { isPro = false }

    private static let key = "isPro"
}
