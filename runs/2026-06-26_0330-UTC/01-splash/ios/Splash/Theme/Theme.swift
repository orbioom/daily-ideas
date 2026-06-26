import SwiftUI

enum SplashTheme {
    static let accent = Color.accentColor
    static let background = Color("SplashBackground")
    static let card = Color("CardBackground")

    static let strokeColors: [String: Color] = [
        "freestyle": Color(red: 0.0, green: 0.71, blue: 0.93),
        "backstroke": Color(red: 0.28, green: 0.52, blue: 0.93),
        "breaststroke": Color(red: 0.20, green: 0.80, blue: 0.60),
        "butterfly": Color(red: 0.93, green: 0.45, blue: 0.20),
        "im": Color(red: 0.75, green: 0.35, blue: 0.93),
        "kick": Color(red: 0.93, green: 0.75, blue: 0.20),
        "pull": Color(red: 0.93, green: 0.25, blue: 0.45),
        "drill": Color(red: 0.55, green: 0.75, blue: 0.93)
    ]

    static func strokeColor(_ stroke: String) -> Color {
        strokeColors[stroke] ?? .blue
    }

    static let intensityColors: [String: Color] = [
        "easy": Color(red: 0.20, green: 0.80, blue: 0.60),
        "moderate": Color(red: 0.0, green: 0.71, blue: 0.93),
        "hard": Color(red: 0.93, green: 0.45, blue: 0.20),
        "race": Color(red: 0.93, green: 0.20, blue: 0.30)
    ]

    static func intensityColor(_ intensity: String) -> Color {
        intensityColors[intensity] ?? .blue
    }
}

extension String {
    var strokeDisplayName: String {
        switch self {
        case "freestyle": return "Freestyle"
        case "backstroke": return "Backstroke"
        case "breaststroke": return "Breaststroke"
        case "butterfly": return "Butterfly"
        case "im": return "IM"
        case "kick": return "Kick"
        case "pull": return "Pull"
        case "drill": return "Drill"
        default: return self.capitalized
        }
    }

    var strokeIcon: String {
        switch self {
        case "freestyle": return "figure.pool.swim"
        case "backstroke": return "arrow.left.circle.fill"
        case "breaststroke": return "circle.hexagongrid.fill"
        case "butterfly": return "wind"
        case "im": return "4.square.fill"
        case "kick": return "figure.kickboxing"
        case "pull": return "hand.raised.fill"
        case "drill": return "slider.horizontal.3"
        default: return "circle.fill"
        }
    }

    var intensityDisplayName: String {
        switch self {
        case "easy": return "Easy"
        case "moderate": return "Moderate"
        case "hard": return "Hard"
        case "race": return "Race Pace"
        default: return self.capitalized
        }
    }

    var poolTypeDisplayName: String {
        switch self {
        case "indoor": return "Indoor"
        case "outdoor": return "Outdoor"
        case "openWater": return "Open Water"
        default: return self.capitalized
        }
    }

    var poolTypeIcon: String {
        switch self {
        case "indoor": return "building.2.fill"
        case "outdoor": return "sun.max.fill"
        case "openWater": return "water.waves"
        default: return "drop.fill"
        }
    }
}

func formatDuration(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
}

func formatPace(_ secondsPer100m: Double, useYards: Bool) -> String {
    let unit = useYards ? "yd" : "m"
    let totalInt = Int(secondsPer100m)
    let m = totalInt / 60
    let s = totalInt % 60
    return String(format: "%d:%02d / 100\(unit)", m, s)
}

func metersToDisplay(_ meters: Double, useYards: Bool) -> String {
    if useYards {
        let yards = meters * 1.09361
        if yards >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f yd", yards)
    }
    if meters >= 1000 {
        return String(format: "%.2f km", meters / 1000)
    }
    return String(format: "%.0f m", meters)
}
