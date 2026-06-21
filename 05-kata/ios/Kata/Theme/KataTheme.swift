import SwiftUI

enum KataTheme {
    static let background = Color(red: 0.08, green: 0.06, blue: 0.04)
    static let surface = Color(red: 0.14, green: 0.11, blue: 0.08)
    static let accent = Color(red: 0.98, green: 0.42, blue: 0.12)
    static let accentYellow = Color(red: 0.98, green: 0.82, blue: 0.12)
    static let textPrimary = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let textSecondary = Color(red: 0.60, green: 0.55, blue: 0.48)
    static let correctGreen = Color(red: 0.3, green: 0.85, blue: 0.45)
    static let warningRed = Color(red: 0.95, green: 0.25, blue: 0.25)
    static let timerActive = Color(red: 0.98, green: 0.42, blue: 0.12)
}

enum WODType: String, CaseIterable, Codable {
    case amrap = "AMRAP"
    case forTime = "For Time"
    case emom = "EMOM"
    case tabata = "Tabata"
    case chipper = "Chipper"
    case ladder = "Ladder"
    case custom = "Custom"

    var description: String {
        switch self {
        case .amrap: return "As Many Rounds As Possible"
        case .forTime: return "Complete as fast as possible"
        case .emom: return "Every Minute on the Minute"
        case .tabata: return "20s work / 10s rest"
        case .chipper: return "Move through all movements once"
        case .ladder: return "Increasing or decreasing reps"
        case .custom: return "Custom structure"
        }
    }
}

enum MovementCategory: String, CaseIterable, Codable {
    case gymnastics = "Gymnastics"
    case weightlifting = "Weightlifting"
    case monostructural = "Monostructural"
    case core = "Core"
    case other = "Other"
}
