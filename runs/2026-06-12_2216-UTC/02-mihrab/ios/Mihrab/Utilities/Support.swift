import SwiftUI
import UIKit

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// Centralized access to the user's chosen city + calculation preferences.
struct PrayerSettings {
    var city: City
    var method: CalculationMethod
    var hanafiAsr: Bool
    var use24Hour: Bool

    static func current() -> PrayerSettings {
        let defaults = UserDefaults.standard
        let cityID = defaults.string(forKey: "cityID") ?? Gazetteer.defaultCityID
        let methodRaw = defaults.string(forKey: "method") ?? CalculationMethod.mwl.rawValue
        return PrayerSettings(
            city: Gazetteer.city(id: cityID) ?? Gazetteer.cities[0],
            method: CalculationMethod(rawValue: methodRaw) ?? .mwl,
            hanafiAsr: defaults.bool(forKey: "hanafiAsr"),
            use24Hour: defaults.bool(forKey: "use24Hour")
        )
    }

    func times(on date: Date) -> PrayerTimes {
        PrayerEngine.times(
            on: date,
            latitude: city.latitude,
            longitude: city.longitude,
            timeZone: city.timeZone,
            method: method,
            hanafiAsr: hanafiAsr
        )
    }

    func timeFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.timeZone = city.timeZone
        f.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return f
    }

    func hijriString(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.timeZone = city.timeZone
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: date) + " AH"
    }
}
