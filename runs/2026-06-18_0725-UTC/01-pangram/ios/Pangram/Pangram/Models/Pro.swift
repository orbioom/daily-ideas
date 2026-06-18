import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready (swap the unlock action for a real purchase),
/// but no real transactions here.
@MainActor final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false

    /// Free players get a small number of fresh practice puzzles per day.
    static let freePracticePerDay = 3

    let priceLabel = "$3.99"

    func unlock() {
        isPro = true
    }

    /// Simulated restore. With no prior purchase recorded, this is a no-op that simply
    /// reports the current entitlement state to the caller.
    func restore() -> Bool {
        isPro
    }
}

struct ProBenefit: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let detail: String
}

extension ProBenefit {
    static let all: [ProBenefit] = [
        ProBenefit(symbol: "infinity", title: "Unlimited practice", detail: "Generate as many fresh puzzles as you like — no daily cap."),
        ProBenefit(symbol: "calendar", title: "Full daily archive", detail: "Replay and complete every past Daily, all the way back."),
        ProBenefit(symbol: "lightbulb.max", title: "Hints page", detail: "The two-way grid of remaining words by length and first letter."),
        ProBenefit(symbol: "paintpalette", title: "Extra hex themes", detail: "Unlock alternate honeycomb palettes for the board."),
        ProBenefit(symbol: "chart.bar.xaxis", title: "Advanced stats", detail: "Full history charts, Genius rate, and score distribution.")
    ]
}
