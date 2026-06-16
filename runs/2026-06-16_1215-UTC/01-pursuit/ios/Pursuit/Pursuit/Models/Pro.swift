import SwiftUI

/// Simulated, StoreKit-ready one-time Pro unlock.
/// In production this flag would be set by a verified StoreKit 2 transaction.
@MainActor final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false

    /// Free tier may keep this many *active* (non-archived) applications.
    static let freeApplicationCap = 15

    /// Display price for the one-time unlock.
    static let priceText = "$4.99"
    static let productName = "Pursuit Pro"

    func unlock() { isPro = true }

    /// Simulated restore. With no prior purchase recorded there is nothing to restore.
    func restore() -> Bool { isPro }
}

/// The concrete benefits surfaced on the paywall.
struct ProBenefit: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let detail: String

    static let all: [ProBenefit] = [
        ProBenefit(symbol: "infinity",
                   title: "Unlimited applications",
                   detail: "Track your whole search — past the free 15-application limit."),
        ProBenefit(symbol: "chart.xyaxis.line",
                   title: "Full Insights",
                   detail: "Conversion funnel, source breakdown, time-to-response and goal ring."),
        ProBenefit(symbol: "square.and.arrow.up",
                   title: "CSV export",
                   detail: "Export your pipeline as a spreadsheet-ready CSV file."),
        ProBenefit(symbol: "tag.fill",
                   title: "Custom tags & colors",
                   detail: "Create and color your own tags to organize roles your way."),
        ProBenefit(symbol: "lock.shield.fill",
                   title: "Private & one-time",
                   detail: "Everything stays on your device. Pay once, keep it forever.")
    ]
}
