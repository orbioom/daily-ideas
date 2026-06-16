import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready: swap the `unlock()` body for a real
/// `Product.purchase()` flow without touching call sites.
enum Pro {
    static let price = "$2.99"
    static let productName = "Pip Pro"

    struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let features: [Feature] = [
        .init(icon: "cpu.fill", title: "CPU opponents",
              detail: "Play 1–3 computer rivals across three difficulties."),
        .init(icon: "paintpalette.fill", title: "Table & dice themes",
              detail: "Unlock extra felt colors and dice styles."),
        .init(icon: "chart.bar.xaxis", title: "Full statistics",
              detail: "Category averages, score distribution, and trends."),
        .init(icon: "calendar.badge.clock", title: "Daily archive",
              detail: "Replay and review every past Daily challenge."),
        .init(icon: "heart.fill", title: "Support an indie, forever ad-free",
              detail: "One payment. No ads, no subscriptions, no nonsense.")
    ]
}

/// Free-tier limits enforced across the app.
enum FreeLimits {
    /// Pass-and-play is capped at 2 players for free; Pro unlocks 3–4.
    static let maxPassAndPlayPlayersFree = 2
    static let maxPassAndPlayPlayersPro = 4
}
