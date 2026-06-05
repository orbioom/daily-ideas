import Foundation
import SwiftUI

/// A named moment in the solar day (twilight phase boundary, golden hour, etc.).
struct SunMoment: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let symbol: String
    let date: Date?
    let tint: Color

    var timeString: String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

/// Definitions of the day's solar moments, in chronological order.
/// Angles in degrees of solar elevation; morning copies mirror in the evening.
enum SunPhase {
    // (label, subtitle, sf-symbol, elevation angle, rising?)
    static let morning: [(String, String, String, Double, Color)] = [
        ("Astronomical dawn", "First faint light", "moon.stars", -18, .orbText3),
        ("Nautical dawn", "Horizon appears", "moon.haze", -12, .orbText3),
        ("Civil dawn", "Blue hour begins", "cloud.moon", -6, Color(red: 0.42, green: 0.49, blue: 0.69)),
        ("Sunrise", "Golden hour begins", "sunrise", -0.833, Color(red: 0.93, green: 0.66, blue: 0.36)),
        ("Golden hour ends", "Soft warm light", "sun.haze", 6, Color(red: 0.95, green: 0.78, blue: 0.45)),
    ]
    static let evening: [(String, String, String, Double, Color)] = [
        ("Golden hour begins", "Soft warm light", "sun.haze", 6, Color(red: 0.95, green: 0.78, blue: 0.45)),
        ("Sunset", "Golden hour ends", "sunset", -0.833, Color(red: 0.92, green: 0.55, blue: 0.42)),
        ("Civil dusk", "Blue hour ends", "cloud.moon", -6, Color(red: 0.42, green: 0.49, blue: 0.69)),
        ("Nautical dusk", "Horizon fades", "moon.haze", -12, .orbText3),
        ("Astronomical dusk", "Full darkness", "moon.stars", -18, .orbText3),
    ]
}
