import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case solo = "Solo"
    case passAndPlay = "Pass & Play"
    case vsCPU = "vs CPU"
    case daily = "Daily"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .solo: return "person.fill"
        case .passAndPlay: return "person.2.fill"
        case .vsCPU: return "cpu.fill"
        case .daily: return "calendar"
        }
    }

    var blurb: String {
        switch self {
        case .solo: return "Beat your own best score."
        case .passAndPlay: return "Hand the phone around, 2–4 players."
        case .vsCPU: return "Take on up to three CPU opponents."
        case .daily: return "Everyone gets the same dice today."
        }
    }
}
