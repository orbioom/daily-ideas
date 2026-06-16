import SwiftUI

/// Simulated one-time Pro unlock (StoreKit-ready, no real purchase here).
enum Pro {
    static let priceLabel = "$3.99"
    static let productName = "Lodestar Pro"

    struct Perk: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }

    static let perks: [Perk] = [
        Perk(symbol: "sparkles", title: "Full star catalog & all constellations",
             detail: "Plot every bright star and all charted constellation figures, not just the brightest."),
        Perk(symbol: "clock.arrow.circlepath", title: "Time travel",
             detail: "Set any date and time to preview the sky — eclipses, meteor showers, a birthday's stars."),
        Perk(symbol: "book.closed", title: "Stargazing journal",
             detail: "Log what you observed, where and when, and build your own observing record."),
        Perk(symbol: "globe.europe.africa", title: "Every city",
             detail: "Unlock the full world gazetteer plus unlimited custom coordinates."),
        Perk(symbol: "moon.stars", title: "Support an indie, no subscription",
             detail: "A single fair price. No account, no ads, no monthly fee — ever.")
    ]
}
