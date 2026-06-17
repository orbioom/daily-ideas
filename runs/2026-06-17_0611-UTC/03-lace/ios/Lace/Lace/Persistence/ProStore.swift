import SwiftUI
import Observation

/// Simulated one-time purchase manager for Lace Pro. StoreKit-ready in spirit;
/// persists the unlocked flag via UserDefaults so it survives relaunch. No real
/// StoreKit calls. The entire Couch-to-5K core is free; Pro adds extra plans,
/// the custom builder, CSV export and themes.
@Observable
final class ProStore {
    @ObservationIgnored private let defaults: UserDefaults
    static let priceDisplay = "$4.99"

    var isPro: Bool { didSet { defaults.set(isPro, forKey: "isPro") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isPro = defaults.bool(forKey: "isPro")
    }

    /// Pro-gated capabilities, surfaced on the paywall.
    static let features: [(icon: String, title: String, detail: String)] = [
        ("figure.walk.motion", "Easy Start plan", "A gentler 12-week ramp with shorter run intervals."),
        ("flag.checkered", "5K → 10K Bridge", "Six weeks that grow your 5K base toward a 10K."),
        ("slider.horizontal.3", "Custom plan builder", "Design your own run/walk sessions, interval by interval."),
        ("square.and.arrow.up", "CSV export", "Export your full training history for spreadsheets."),
        ("paintpalette", "Extra themes", "Fresh color themes for the player and rings.")
    ]

    func unlock() { isPro = true }
    func restore() { isPro = true }
    func lockForDemo() { isPro = false }
}
