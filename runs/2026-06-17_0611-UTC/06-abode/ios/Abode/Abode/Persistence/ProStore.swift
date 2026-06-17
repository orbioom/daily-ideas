import SwiftUI
import Observation

/// Simulated one-time purchase manager. StoreKit-ready in spirit; persists the unlocked
/// flag via UserDefaults so it survives relaunch. No real StoreKit calls.
@Observable
final class ProStore {
    @ObservationIgnored private let defaults: UserDefaults
    static let priceDisplay = "$3.99"

    /// Persisted entitlement, mirrored to UserDefaults.
    var isPro: Bool { didSet { defaults.set(isPro, forKey: "isPro") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isPro = defaults.bool(forKey: "isPro")
    }

    /// Pro-gated capabilities surfaced on the paywall.
    static let features: [(icon: String, title: String, detail: String)] = [
        ("square.stack.3d.up.fill", "Unlimited scenarios", "Save and compare as many homes and loans as you like."),
        ("arrow.left.arrow.right", "Refinance compare", "See monthly savings, break-even, and lifetime interest delta."),
        ("house.and.flag.fill", "Affordability solver", "Find your max price from income, debts, and DTI targets."),
        ("bolt.fill", "Extra-payment optimizer", "Model extra, one-time, and biweekly payoff strategies."),
        ("square.and.arrow.up.fill", "Export", "Share your amortization schedule and breakdowns.")
    ]

    /// Saved scenarios allowed on the free tier.
    static let freeScenarioLimit = 2

    func unlock() { isPro = true }
    func restore() { isPro = true }
    func lockForDemo() { isPro = false }
}
