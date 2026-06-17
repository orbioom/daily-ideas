import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready: swap `setPro` for a real
/// purchase/restore flow without touching call sites.
@MainActor
enum Pro {
    static let priceLabel = "$3.99"
    static let productTitle = "Tangle Pro"

    /// The hint cap a player gets for free; Pro grants unlimited hints.
    static let freeHintCap = 5
    /// Free players can play levels in the first pack only.
    static let freePackCount = 1

    static let unlocks: [String] = [
        "Every level pack — over a hundred hand-crafted puzzles",
        "Unlimited hints, no waiting for refills",
        "Relaxed Mode — no win pressure, just unwind",
        "Bonus-word definitions in your Word Jar",
        "Fresh seasonal packs added for free, forever"
    ]
}
