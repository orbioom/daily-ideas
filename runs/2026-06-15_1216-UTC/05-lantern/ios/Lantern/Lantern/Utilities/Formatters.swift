import Foundation

enum TimeFormat {
    /// "m:ss" for under an hour, "h:mm:ss" beyond.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }
}

extension TileFace {
    /// A human-readable name used for VoiceOver labels.
    var spokenName: String {
        switch self {
        case .bamboo(let n): return "Bamboo \(n)"
        case .characters(let n): return "Characters \(n)"
        case .circles(let n): return "Circles \(n)"
        case .wind(let w):
            switch w {
            case .east: return "East Wind"
            case .south: return "South Wind"
            case .west: return "West Wind"
            case .north: return "North Wind"
            }
        case .dragon(let d):
            switch d {
            case .red: return "Red Dragon"
            case .green: return "Green Dragon"
            case .white: return "White Dragon"
            }
        case .flower(let f):
            switch f {
            case .plum: return "Plum Flower"
            case .orchid: return "Orchid Flower"
            case .bamboo: return "Bamboo Flower"
            case .chrysanthemum: return "Chrysanthemum Flower"
            }
        case .season(let s):
            switch s {
            case .spring: return "Spring Season"
            case .summer: return "Summer Season"
            case .autumn: return "Autumn Season"
            case .winter: return "Winter Season"
            }
        }
    }
}
