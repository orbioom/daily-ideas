import SwiftUI

enum KegTheme {
    static let accent = Color.accentColor
    static let background = Color("KegBackground")

    static func srmColor(_ srm: Double) -> Color {
        switch srm {
        case ..<3: return Color(red: 0.97, green: 0.95, blue: 0.75)
        case 3..<6: return Color(red: 0.97, green: 0.86, blue: 0.40)
        case 6..<9: return Color(red: 0.93, green: 0.65, blue: 0.17)
        case 9..<14: return Color(red: 0.80, green: 0.40, blue: 0.08)
        case 14..<18: return Color(red: 0.60, green: 0.25, blue: 0.04)
        case 18..<25: return Color(red: 0.35, green: 0.15, blue: 0.02)
        case 25..<35: return Color(red: 0.18, green: 0.08, blue: 0.01)
        default: return Color(red: 0.06, green: 0.03, blue: 0.01)
        }
    }

    static func statusColor(_ status: String) -> Color {
        switch status {
        case "planned": return .gray
        case "fermenting": return .blue
        case "conditioning": return .orange
        case "kegged", "bottled": return .green
        case "complete": return Color(red: 0.6, green: 0.1, blue: 0.7)
        default: return .gray
        }
    }
}

extension Double {
    var gravityDisplay: String {
        String(format: "%.3f", self)
    }
}

func volumeDisplay(_ liters: Double, useMetric: Bool) -> String {
    if useMetric {
        return String(format: "%.1f L", liters)
    }
    return String(format: "%.1f gal", liters * 0.264172)
}

func tempDisplay(_ celsius: Double, useCelsius: Bool) -> String {
    if useCelsius {
        return String(format: "%.1f°C", celsius)
    }
    return String(format: "%.1f°F", celsius * 9 / 5 + 32)
}
