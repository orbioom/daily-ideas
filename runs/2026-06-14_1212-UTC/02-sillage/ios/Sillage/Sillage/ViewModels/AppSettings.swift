import SwiftUI

/// Sort options for the collection grid.
enum CollectionSort: String, CaseIterable, Identifiable {
    case added = "Recently added"
    case mostWorn = "Most worn"
    case costPerWear = "Cost per wear"
    case rating = "Rating"
    case name = "Name"
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .added: return "clock"
        case .mostWorn: return "flame"
        case .costPerWear: return "dollarsign.circle"
        case .rating: return "star"
        case .name: return "textformat"
        }
    }
}

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("priceCurrencySymbol") var priceCurrencySymbol: String = "$"
    @AppStorage("defaultSortRaw") var defaultSortRaw: String = CollectionSort.added.rawValue
    @AppStorage("neglectedDays") var neglectedDays: Int = 60
    @AppStorage("hidePrices") var hidePrices: Bool = false
    @AppStorage("showLongevityHints") var showLongevityHints: Bool = true

    var defaultSort: CollectionSort {
        get { CollectionSort(rawValue: defaultSortRaw) ?? .added }
        set { defaultSortRaw = newValue.rawValue }
    }

    /// Format a money amount with the chosen currency symbol (respects hide-prices).
    func formatMoney(_ value: Double) -> String {
        if hidePrices { return "•••" }
        let symbol = priceCurrencySymbol.isEmpty ? "$" : priceCurrencySymbol
        return symbol + String(format: "%.2f", value)
    }

    /// Money string ignoring the hide-prices toggle (for editors where the user types it).
    func formatMoneyAlways(_ value: Double) -> String {
        let symbol = priceCurrencySymbol.isEmpty ? "$" : priceCurrencySymbol
        return symbol + String(format: "%.2f", value)
    }
}
