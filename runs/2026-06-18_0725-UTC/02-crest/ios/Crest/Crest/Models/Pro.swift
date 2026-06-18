import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready: swap `unlock()` for a real
/// purchase flow later. State persists in @AppStorage so it survives relaunch.
@MainActor final class ProStore: ObservableObject {
    @AppStorage("isPro") var isProStored = false {
        didSet { objectWillChange.send() }
    }

    var isPro: Bool { isProStored }

    let priceLabel = "$3.99"

    struct Perk: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    let perks: [Perk] = [
        Perk(icon: "triangle.fill", title: "Pyramid & Diamond boards",
             detail: "Two extra layouts beyond classic Three Peaks."),
        Perk(icon: "calendar", title: "Daily archive",
             detail: "Play and replay any past daily deal."),
        Perk(icon: "paintpalette.fill", title: "Extra felt & card themes",
             detail: "Midnight, Sunset and Slate table felts."),
        Perk(icon: "square.and.arrow.up", title: "Stats export",
             detail: "Export your full game history as CSV."),
        Perk(icon: "heart.fill", title: "Support indie, ad-free",
             detail: "No ads, ever. One payment, yours forever.")
    ]

    func unlock() { isProStored = true }

    /// Simulated restore — in a real build this would query StoreKit.
    func restore() { isProStored = true }
}
