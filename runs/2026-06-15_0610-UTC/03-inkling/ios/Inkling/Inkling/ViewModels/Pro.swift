import Foundation

/// Inkling's free/Pro split. The whole hook vs Bearable is that correlations AND unlimited history
/// are FREE here. Pro is a one-time unlock for power features only.
/// Free: unlimited trackers + logging + same-day correlations + unlimited history.
/// Pro: next-day (lag) analysis, CSV export, custom symbols/themes, multi-day experiments.
enum Pro {
    static let priceLabel = "$5.99"

    /// The perks shown on the paywall and Settings.
    static let perks: [(symbol: String, text: String)] = [
        ("clock.arrow.circlepath", "Next-day (lag) correlation analysis"),
        ("square.and.arrow.up", "Export your full history to CSV"),
        ("paintpalette", "Custom symbols & accent themes"),
        ("flask", "Multi-day experiments to test a change")
    ]
}

/// Why the paywall is being shown — sets its headline and copy.
enum PaywallReason: Identifiable {
    case lag
    case export
    case experiments
    case general

    var id: String {
        switch self {
        case .lag: return "lag"
        case .export: return "export"
        case .experiments: return "experiments"
        case .general: return "general"
        }
    }

    var symbol: String {
        switch self {
        case .lag: return "clock.arrow.circlepath"
        case .export: return "square.and.arrow.up"
        case .experiments: return "flask"
        case .general: return "sparkles"
        }
    }

    var title: String {
        switch self {
        case .lag: return "See next-day effects"
        case .export: return "Export your history"
        case .experiments: return "Run an experiment"
        case .general: return "Unlock Inkling Pro"
        }
    }

    var blurb: String {
        switch self {
        case .lag:
            return "Some factors don't hit until tomorrow. Inkling Pro adds next-day (lag) correlation so you can catch a late caffeine crash or a poor-sleep hangover."
        case .export:
            return "Your history is always yours and unlimited — for free. Inkling Pro lets you export every entry to a CSV to share with a clinician or back up."
        case .experiments:
            return "Pick one change, set a window, and Inkling tracks whether your symptoms actually move. A focused multi-day test, Pro only."
        case .general:
            return "Correlations and unlimited history are free, forever. Inkling Pro is a one-time unlock for lag analysis, CSV export, custom themes, and experiments."
        }
    }
}
