import SwiftUI

/// Sort options for the ranked list.
enum ListSort: String, CaseIterable, Identifiable {
    case rank = "Rank"
    case score = "Score"
    case name = "Name"
    case recent = "Recent"
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .rank: return "list.number"
        case .score: return "number"
        case .name: return "textformat"
        case .recent: return "clock"
        }
    }
}

/// How the 0–10 score is rendered.
enum ScoreScaleStyle: String, CaseIterable, Identifiable {
    case oneDecimal = "9.4"
    case wholeNumber = "9"
    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneDecimal: return "One decimal (9.4)"
        case .wholeNumber: return "Whole number (9)"
        }
    }
}

/// Persisted user preferences that actually change behavior.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("priceCurrencySymbol") var priceCurrencySymbol: String = "$"
    @AppStorage("defaultSortRaw") var defaultSortRaw: String = ListSort.rank.rawValue
    @AppStorage("scoreScaleStyleRaw") var scoreScaleStyleRaw: String = ScoreScaleStyle.oneDecimal.rawValue
    @AppStorage("showTierHeaders") var showTierHeaders: Bool = true

    var defaultSort: ListSort {
        get { ListSort(rawValue: defaultSortRaw) ?? .rank }
        set { defaultSortRaw = newValue.rawValue }
    }

    var scoreScaleStyle: ScoreScaleStyle {
        get { ScoreScaleStyle(rawValue: scoreScaleStyleRaw) ?? .oneDecimal }
        set { scoreScaleStyleRaw = newValue.rawValue }
    }

    /// Format a 0–10 score per the chosen style.
    func formatScore(_ value: Double) -> String {
        let clamped = min(max(value, 0), 10)
        switch scoreScaleStyle {
        case .oneDecimal:
            return String(format: "%.1f", clamped)
        case .wholeNumber:
            return String(Int(clamped.rounded()))
        }
    }

    /// Format a money amount with the chosen currency symbol.
    func formatMoney(_ value: Double) -> String {
        let symbol = priceCurrencySymbol.isEmpty ? "$" : priceCurrencySymbol
        return symbol + String(format: "%.2f", value)
    }
}
