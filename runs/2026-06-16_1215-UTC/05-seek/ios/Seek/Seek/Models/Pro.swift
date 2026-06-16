import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready: swap the setter for a real purchase flow.
@MainActor
final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false {
        willSet { objectWillChange.send() }
    }

    /// One-time price, modeled with Decimal for correctness (no Double currency math).
    let price = Decimal(string: "2.99") ?? Decimal(299) / Decimal(100)
    let currencyCode = "USD"

    var priceLabel: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .current
        return formatter.string(from: price as NSDecimalNumber) ?? "$2.99"
    }

    func unlock() {
        isPro = true
    }

    func restore() {
        // Simulated restore: in production this queries StoreKit for prior purchases.
        isPro = true
    }
}

/// Free-tier limits enforced across the app.
enum FreeTier {
    /// Number of free packs (the first N are free).
    static let packCount = 3
    /// Free puzzles per pack, per difficulty.
    static let puzzlesPerPackPerDifficulty = 5
    /// Free hints per puzzle.
    static let hintsPerPuzzle = 3

    /// Total puzzle indices offered per pack per difficulty.
    static let totalPuzzlesPerPackPerDifficulty = 10
}
