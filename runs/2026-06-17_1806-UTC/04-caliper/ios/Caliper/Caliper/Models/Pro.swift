import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready: replace the `unlock`/`restore`
/// bodies with real StoreKit 2 purchase/restore calls; the rest of the app reads
/// `isPro` and needs no changes.
@MainActor
final class ProStore: ObservableObject {
    @AppStorage("isPro") var isProStored = false {
        didSet { objectWillChange.send() }
    }

    var isPro: Bool { isProStored }

    /// One-time price label shown on the paywall.
    let priceLabel = "$4.99"

    let unlocks: [ProUnlock] = [
        ProUnlock(icon: "ruler", title: "Every measurement site",
                  detail: "Track all 14 body sites plus your own custom sites."),
        ProUnlock(icon: "chart.xyaxis.line", title: "Advanced insights",
                  detail: "FFMI, full 30/90/365/all-time windows and composition view."),
        ProUnlock(icon: "target", title: "Unlimited goals",
                  detail: "Set a target on every site, not just one."),
        ProUnlock(icon: "square.and.arrow.up", title: "CSV export",
                  detail: "Export your full history for backup or your spreadsheet."),
        ProUnlock(icon: "clock.arrow.circlepath", title: "Full history",
                  detail: "See and chart entries older than 90 days.")
    ]

    func unlock() { isProStored = true }

    /// Simulated restore. In production this calls StoreKit's restore flow.
    func restore() { isProStored = true }
}

struct ProUnlock: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}

/// Central place that defines what Free can do vs Pro.
enum ProGate {
    /// Site keys available to free users (core logging is never gated).
    static let freeSiteKeys: Set<String> = ["weight", "bodyfat", "waist", "neck", "chest", "hips"]
    /// Free users may set at most this many goals.
    static let freeGoalLimit = 1
    /// Free users can chart/inspect entries within this many days.
    static let freeHistoryDays = 90
    /// Insight windows available to free users (in days; nil = all-time).
    static let freeWindowDays: [Int] = [30]
}
