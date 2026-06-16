import Foundation

/// Digit Pro — a simulated one-time unlock (StoreKit-ready, not wired to real IAP).
enum Pro {
    static let priceLabel = "$4.99"
    static let productName = "Digit Pro"

    struct Perk: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }

    static let perks: [Perk] = [
        Perk(symbol: "person.3.fill",
             title: "Unlimited child profiles",
             detail: "One clean dashboard for the whole family. Free includes one profile."),
        Perk(symbol: "multiply.circle.fill",
             title: "Multiplication & division",
             detail: "Unlock times tables, division facts and every level beyond add/subtract."),
        Perk(symbol: "chart.xyaxis.line",
             title: "Full parent analytics",
             detail: "Speed & accuracy trends, the mastery grid and facts-over-time charts."),
        Perk(symbol: "rosette",
             title: "All badges & the full Level Map",
             detail: "Every reward and level unlocks as your child grows."),
        Perk(symbol: "heart.fill",
             title: "One-time purchase, no ads",
             detail: "Pay once, own it forever. No subscriptions, ever.")
    ]

    /// Free tier allows a single child profile.
    static let freeProfileLimit = 1
}
