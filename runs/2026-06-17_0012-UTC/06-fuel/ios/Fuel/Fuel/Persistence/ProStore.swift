import SwiftUI
import Observation

/// Simulated one-time purchase manager. StoreKit-ready in spirit; persists the
/// unlocked flag via @AppStorage so it survives relaunch. No real StoreKit calls.
@Observable
final class ProStore {
    @ObservationIgnored private let defaults: UserDefaults
    static let priceDisplay = "$5.99"

    /// Persisted entitlement. Stored so observation fires; mirrored to UserDefaults.
    var isPro: Bool { didSet { defaults.set(isPro, forKey: "isPro") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isPro = defaults.bool(forKey: "isPro")
    }

    /// The set of Pro-gated capabilities, surfaced on the paywall.
    static let features: [(icon: String, title: String, detail: String)] = [
        ("wand.and.stars", "Adaptive recalibration", "Auto-tune your target from weekly weigh-ins."),
        ("calendar.badge.clock", "Refeed & diet-break planner", "Scheduled maintenance breaks to protect your cut."),
        ("clock.arrow.circlepath", "Unlimited history", "Keep every check-in and target snapshot forever."),
        ("square.stack.3d.up", "Multi-phase goals", "Chain cut → maintain → bulk phases."),
        ("square.and.arrow.up", "CSV export", "Export your full data for spreadsheets.")
    ]

    /// Number of most-recent check-ins visible on the free tier.
    static let freeHistoryLimit = 5

    func unlock() { isPro = true }
    func restore() { isPro = true }
    func lockForDemo() { isPro = false }
}
