import SwiftUI

/// Simulated one-time Pro unlock (StoreKit-ready; no real purchases here).
/// Stored as a single @AppStorage flag so it survives relaunch.
@MainActor final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false

    /// Display price; money math (if any) would use Decimal, never Double.
    let price: Decimal = Decimal(string: "2.99") ?? 2.99
    var priceText: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: price as NSDecimalNumber) ?? "$2.99"
    }

    struct Perk: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }

    let perks: [Perk] = [
        Perk(symbol: "lock.open.fill", title: "All level packs", detail: "Unlock every level beyond the free starter pack."),
        Perk(symbol: "arrow.counterclockwise.circle.fill", title: "Daily archive replay", detail: "Re-play any past Daily challenge from the archive."),
        Perk(symbol: "paintpalette.fill", title: "Zen board skins", detail: "Calming gem skins & background themes for Zen mode."),
        Perk(symbol: "chart.bar.fill", title: "Extended stats", detail: "Full history charts with no time-window limits."),
        Perk(symbol: "heart.fill", title: "Support a fair game", detail: "No lives, no timers, no ads — ever. One time.")
    ]

    func unlock() {
        isPro = true
    }
}

/// Pro gating rules used across the app.
enum ProGate {
    static func isLevelLocked(_ level: Level, isPro: Bool) -> Bool {
        // First 8 levels are free; everything past requires Pro.
        !isPro && level.id > LevelCatalog.freePackSize
    }
}
