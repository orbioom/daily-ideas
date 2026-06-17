import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        self == .system ? nil : (self == .light ? .light : .dark)
    }
}

/// App-wide preferences, persisted in `@AppStorage`.
@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue

    // Calculator-specific persisted preferences.
    @AppStorage("groupingEnabled") var groupingEnabled = true
    @AppStorage("decimalPlaces") var decimalPlacesRaw = DecimalPlaces.auto.rawValue
    @AppStorage("defaultAngle") var defaultAngleRaw = AngleUnit.degrees.rawValue
    @AppStorage("highPrecision") var highPrecision = false
    @AppStorage("selectedTheme") var selectedThemeRaw = AppTheme.classic.rawValue

    // Persisted calculator state.
    @AppStorage("memoryRegister") var memoryRegister: Double = 0
    @AppStorage("lastResult") var lastResult = ""

    // Persisted converter state.
    @AppStorage("converterCategory") var converterCategory = "Length"
    @AppStorage("converterFromUnit") var converterFromUnit = "m"
    @AppStorage("converterToUnit") var converterToUnit = "ft"

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var decimalPlaces: DecimalPlaces {
        get { DecimalPlaces(rawValue: decimalPlacesRaw) ?? .auto }
        set { decimalPlacesRaw = newValue.rawValue }
    }

    var defaultAngle: AngleUnit {
        get { AngleUnit(rawValue: defaultAngleRaw) ?? .degrees }
        set { defaultAngleRaw = newValue.rawValue }
    }

    /// The active theme, honoring Pro gating (non-Pro always resolves to classic).
    func activeTheme(isPro: Bool) -> AppTheme {
        let theme = AppTheme(rawValue: selectedThemeRaw) ?? .classic
        return (theme.requiresPro && !isPro) ? .classic : theme
    }

    /// Decimal digits applied to displayed results, raised in high-precision mode.
    var effectivePlaces: Int? {
        guard let base = decimalPlaces.digits else { return nil }
        return highPrecision ? min(base + 4, 12) : base
    }
}
