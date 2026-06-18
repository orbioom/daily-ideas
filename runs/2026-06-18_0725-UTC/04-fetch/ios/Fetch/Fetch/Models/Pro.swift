import SwiftUI

/// Simulated Pro entitlement. StoreKit-ready: swap `isPro` writes for a real
/// transaction listener and this gating logic stays identical.
enum Pro {
    /// Free users can keep one dog.
    static let freeDogLimit = 1
    /// Free users get the first two programs unlocked.
    static let freeProgramCount = 2
    static let priceLabel = "$14.99 one-time"

    static let features: [(icon: String, title: String, detail: String)] = [
        ("dog.fill", "Unlimited dogs", "Track training for your whole pack, not just one."),
        ("rectangle.stack.fill", "All training programs", "Unlock Leash Mastery, Party Tricks and Calm & Focus."),
        ("chart.bar.xaxis", "Advanced stats", "By-category mastery, minutes trends and deeper insights."),
        ("plus.square.on.square", "Custom tricks", "Add your own commands with personalized steps."),
        ("heart.fill", "Support indie dev", "A single fair price \u{2014} no $40/month subscription, ever.")
    ]
}
