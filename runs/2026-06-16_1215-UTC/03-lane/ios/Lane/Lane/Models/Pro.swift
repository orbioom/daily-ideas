import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready: swap `unlock()` / `restore()`
/// for real `Product.purchase()` / `Transaction.currentEntitlements` calls.
@MainActor
final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false

    /// Free tier may create up to this many boards.
    static let freeBoardLimit = 2

    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"

    func unlock() {
        isPro = true
    }

    func restore() -> Bool {
        // In a real build this checks Transaction entitlements. Here the local
        // flag is the source of truth, so restore reports the current state.
        return isPro
    }
}

/// Features gated behind Pro. Used to render the paywall and gate UI.
enum ProFeature: String, CaseIterable, Identifiable {
    case unlimitedBoards
    case customLabels
    case wipLimits
    case insights

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unlimitedBoards: return "Unlimited boards"
        case .customLabels: return "Custom labels"
        case .wipLimits: return "WIP limits"
        case .insights: return "Insights & charts"
        }
    }

    var detail: String {
        switch self {
        case .unlimitedBoards: return "Create as many boards as your work needs — past the free limit of \(ProStore.freeBoardLimit)."
        case .customLabels: return "Build your own colored label set and tag cards your way."
        case .wipLimits: return "Cap each column to keep work-in-progress honest."
        case .insights: return "Throughput charts, column breakdowns, and busiest-board stats."
        }
    }

    var symbol: String {
        switch self {
        case .unlimitedBoards: return "square.stack.3d.up.fill"
        case .customLabels: return "tag.fill"
        case .wipLimits: return "gauge.with.dots.needle.67percent"
        case .insights: return "chart.bar.xaxis"
        }
    }
}
