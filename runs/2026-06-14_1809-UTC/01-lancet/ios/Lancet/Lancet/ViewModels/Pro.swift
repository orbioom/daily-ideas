import Foundation

/// Free-tier gating logic. Logging readings is always free and unlimited;
/// the full Insights screen and CSV export are Pro.
enum Pro {
    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case insights
    case export

    var id: String {
        switch self {
        case .insights: return "insights"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .insights: return "Unlock your full Insights"
        case .export: return "Export your readings"
        }
    }

    var blurb: String {
        switch self {
        case .insights:
            return "See your estimated A1C, time-in-range trends, glucose variability and beautiful charts — all computed privately on your device."
        case .export:
            return "Save every reading as a clean CSV file to share with your care team or keep as a backup."
        }
    }

    var symbol: String {
        switch self {
        case .insights: return "chart.xyaxis.line"
        case .export: return "square.and.arrow.up"
        }
    }
}
