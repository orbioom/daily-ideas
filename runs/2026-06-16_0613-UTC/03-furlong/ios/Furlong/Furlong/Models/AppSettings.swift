import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("distanceUnit") var distanceUnitRaw = DistanceUnit.miles.rawValue
    @AppStorage("currencyCode") var currencyCode = "USD"
    @AppStorage("defaultPurpose") var defaultPurposeRaw = TripPurpose.business.rawValue
    @AppStorage("defaultRoundTrip") var defaultRoundTrip = false

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var distanceUnit: DistanceUnit {
        get { DistanceUnit(rawValue: distanceUnitRaw) ?? .miles }
        set { distanceUnitRaw = newValue.rawValue }
    }

    var defaultPurpose: TripPurpose {
        get { TripPurpose(rawValue: defaultPurposeRaw) ?? .business }
        set { defaultPurposeRaw = newValue.rawValue }
    }

    /// Common ISO currency codes offered in Settings.
    let currencyChoices = ["USD", "CAD", "GBP", "EUR", "AUD", "NZD", "ZAR", "INR"]

    // MARK: Display helpers honoring user settings.

    func money(_ amount: Decimal) -> String {
        CurrencyFormatter.string(amount, code: currencyCode)
    }

    func moneyCompact(_ amount: Decimal) -> String {
        CurrencyFormatter.compact(amount, code: currencyCode)
    }

    /// Render canonical miles in the user's chosen unit, with the short suffix.
    func distance(_ canonicalMiles: Double) -> String {
        let v = distanceUnit.fromMiles(canonicalMiles)
        return "\(NumberFormatting.distance(v)) \(distanceUnit.shortLabel)"
    }

    /// Bare numeric distance (no suffix) in the user's unit.
    func distanceValue(_ canonicalMiles: Double) -> Double {
        distanceUnit.fromMiles(canonicalMiles)
    }
}
