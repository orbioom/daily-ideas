import SwiftUI
import Observation

/// Simulated one-time purchase manager for Hush Pro. StoreKit-ready in spirit;
/// persists the unlocked flag via UserDefaults so it survives relaunch. No real
/// StoreKit calls.
@Observable
final class ProStore {
    @ObservationIgnored private let defaults: UserDefaults
    static let priceDisplay = "$3.99"

    /// Persisted entitlement. Mirrored to UserDefaults on change.
    var isPro: Bool { didSet { defaults.set(isPro, forKey: "isPro") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isPro = defaults.bool(forKey: "isPro")
    }

    /// The set of Pro-gated capabilities, surfaced on the paywall.
    static let features: [(icon: String, title: String, detail: String)] = [
        ("waveform.path.badge.plus", "Full sound library", "Unlock wind, stream, campfire and night-crickets generators."),
        ("square.stack.3d.up.fill", "Unlimited layers", "Stack as many sounds as you like into one mix."),
        ("heart.fill", "Unlimited saved mixes", "Save every blend you love and favorite the best."),
        ("moon.zzz.fill", "Long & custom timers", "Any duration plus longer, gentler fade-outs."),
        ("paintpalette.fill", "All presets", "Every built-in preset mix, not just the starter three.")
    ]

    /// The cap on saved mixes for the free tier.
    static let freeSavedMixLimit = 3

    func unlock() { isPro = true }
    func restore() { isPro = true }
    func lockForDemo() { isPro = false }
}
