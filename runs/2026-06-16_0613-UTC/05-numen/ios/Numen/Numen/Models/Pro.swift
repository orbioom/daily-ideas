import Foundation

/// Simulated Pro entitlement details. StoreKit-ready: swap `isPro` for a real
/// transaction observer and this layer stays the same.
enum Pro {
    static let price = "$3.99"
    static let productName = "Numen Pro"

    /// Free users may keep this many profiles before Pro is required.
    static let freeProfileLimit = 1

    /// Real unlocks shown on the paywall.
    static let unlocks: [ProUnlock] = [
        ProUnlock(symbol: "person.3.fill", title: "Unlimited Profiles", detail: "Read charts for family, friends, and partners — not just yourself."),
        ProUnlock(symbol: "heart.text.square.fill", title: "Compatibility", detail: "Full harmony scoring and per-number breakdowns between any two people."),
        ProUnlock(symbol: "books.vertical.fill", title: "Complete Library", detail: "Every number meaning, 1–9 and the master numbers, unlocked."),
        ProUnlock(symbol: "square.and.arrow.up.fill", title: "Share Cards", detail: "Export a beautiful summary of any reading to share or save."),
        ProUnlock(symbol: "clock.arrow.circlepath", title: "Daily History", detail: "Look back and ahead at your personal-day cycles over time.")
    ]
}

struct ProUnlock: Identifiable {
    let symbol: String
    let title: String
    let detail: String
    var id: String { title }
}
