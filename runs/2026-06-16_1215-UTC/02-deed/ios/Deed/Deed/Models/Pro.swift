import SwiftUI

/// Simulated one-time Pro unlock (StoreKit-ready; no real purchase in this build).
@MainActor
final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false

    /// Free tier is capped at this many properties.
    static let freePropertyCap = 2

    static let priceLabel = "$7.99"
    static let productName = "Deed Pro"

    func unlock() { isPro = true }

    /// Simulated restore — re-reads the persisted flag.
    func restore() -> Bool { isPro }

    func canAddProperty(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freePropertyCap
    }
}

struct ProBenefit: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let detail: String

    static let all: [ProBenefit] = [
        ProBenefit(systemImage: "infinity",
                   title: "Unlimited properties",
                   detail: "Track your whole portfolio past the 2-property free limit."),
        ProBenefit(systemImage: "chart.bar.xaxis",
                   title: "Reports & insights",
                   detail: "Income vs. expense, cash-flow trend, and expense breakdown charts."),
        ProBenefit(systemImage: "square.and.arrow.up",
                   title: "CSV export",
                   detail: "Export transactions and rent roll for taxes or your accountant."),
        ProBenefit(systemImage: "function",
                   title: "Advanced metrics",
                   detail: "Cap rate, cash-on-cash, GRM, and expense ratio on every property."),
        ProBenefit(systemImage: "lock.shield",
                   title: "Private & on-device",
                   detail: "Your numbers never leave your phone — no cloud, no account.")
    ]
}
