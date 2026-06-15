import SwiftUI

/// How the wallet grid is sorted. Persisted as a raw string.
enum CardSortOrder: String, CaseIterable, Identifiable {
    case recentlyUsed
    case name
    case dateAdded
    case category

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recentlyUsed: return "Recently Used"
        case .name:         return "Name"
        case .dateAdded:    return "Date Added"
        case .category:     return "Category"
        }
    }

    var symbol: String {
        switch self {
        case .recentlyUsed: return "clock.arrow.circlepath"
        case .name:         return "textformat"
        case .dateAdded:    return "calendar"
        case .category:     return "square.grid.2x2"
        }
    }
}

/// The user's preferred color scheme override for the app.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    /// Sparse haptics on save / mark-used / spend.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Boost screen brightness to max while a card's barcode is shown.
    @AppStorage("brightnessBoost") var brightnessBoost: Bool = true
    /// The default barcode format pre-selected when adding a new card.
    @AppStorage("defaultFormat") var defaultFormatRaw: String = BarcodeFormat.code128.rawValue
    /// Wallet sort order.
    @AppStorage("sortOrder") var sortOrderRaw: String = CardSortOrder.recentlyUsed.rawValue
    /// Light / dark / system override.
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue

    var defaultFormat: BarcodeFormat {
        get { BarcodeFormat(rawValue: defaultFormatRaw) ?? .code128 }
        set { defaultFormatRaw = newValue.rawValue }
    }

    var sortOrder: CardSortOrder {
        get { CardSortOrder(rawValue: sortOrderRaw) ?? .recentlyUsed }
        set { sortOrderRaw = newValue.rawValue }
    }

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
