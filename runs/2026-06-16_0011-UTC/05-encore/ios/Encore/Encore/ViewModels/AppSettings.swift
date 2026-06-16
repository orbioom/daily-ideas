import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// How the Shows library is ordered by default.
enum ShowSort: String, CaseIterable, Identifiable {
    case dateNewest = "Newest first"
    case dateOldest = "Oldest first"
    case artist = "Artist"
    case rating = "Rating"
    case venue = "Venue"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .dateNewest: return "arrow.down"
        case .dateOldest: return "arrow.up"
        case .artist: return "textformat"
        case .rating: return "star"
        case .venue: return "building.2"
        }
    }
}

/// App-wide persisted preferences. All values survive relaunch via `@AppStorage`.
@MainActor
final class AppSettings: ObservableObject {
    /// Gates all haptic feedback.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// System / Light / Dark.
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue
    /// ISO currency code used to format ticket prices everywhere.
    @AppStorage("currencyCode") var currencyCode: String = "USD"
    /// Default sort applied to the Shows library on appear.
    @AppStorage("defaultSortRaw") var defaultSortRaw: String = ShowSort.dateNewest.rawValue
    /// Show the live countdown banner / chips for upcoming wishlist shows.
    @AppStorage("showCountdowns") var showCountdowns: Bool = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultSort: ShowSort {
        get { ShowSort(rawValue: defaultSortRaw) ?? .dateNewest }
        set { defaultSortRaw = newValue.rawValue }
    }

    /// Format a Decimal price in the chosen currency.
    func money(_ amount: Decimal) -> String {
        CurrencyFormatter.string(amount, code: currencyCode)
    }

    /// A short symbol-only currency hint for compact chips.
    var currencySymbol: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }

    /// Currency codes offered in Settings.
    static let currencyCodes: [String] = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "INR", "BRL", "MXN", "SEK"]
}
