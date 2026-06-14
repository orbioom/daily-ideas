import SwiftUI

/// Time-display preference.
enum TimeFormatPref: String, CaseIterable, Identifiable {
    case twelveHour = "12h"
    case twentyFourHour = "24h"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .twelveHour: return "12-hour"
        case .twentyFourHour: return "24-hour"
        }
    }
    var use24h: Bool { self == .twentyFourHour }
}

/// Persisted user preferences. Plain UserDefaults only — never trip data.
@MainActor
final class AppSettings: ObservableObject {

    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true {
        didSet { objectWillChange.send() }
    }

    @AppStorage("currencySymbol") var currencySymbol: String = "$" {
        didSet { objectWillChange.send() }
    }

    @AppStorage("timeFormat") var timeFormatRaw: String = TimeFormatPref.twelveHour.rawValue {
        didSet { objectWillChange.send() }
    }

    @AppStorage("defaultPackingTemplate") var defaultPackingTemplateRaw: String = PackingEngine.Template.city.rawValue {
        didSet { objectWillChange.send() }
    }

    var timeFormat: TimeFormatPref {
        get { TimeFormatPref(rawValue: timeFormatRaw) ?? .twelveHour }
        set { timeFormatRaw = newValue.rawValue }
    }

    var defaultPackingTemplate: PackingEngine.Template {
        get { PackingEngine.Template(rawValue: defaultPackingTemplateRaw) ?? .city }
        set { defaultPackingTemplateRaw = newValue.rawValue }
    }

    /// Common currency symbols offered in Settings / add-trip.
    static let currencyOptions: [String] = ["$", "€", "£", "¥", "₹", "₩", "₣", "kr"]
}
