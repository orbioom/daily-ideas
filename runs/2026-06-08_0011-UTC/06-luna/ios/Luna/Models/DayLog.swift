import Foundation
import SwiftData
import SwiftUI

/// Per-day tracking: flow intensity, symptoms, mood, and a note.
@Model
final class DayLog {
    var id: UUID
    var date: Date
    var flowRaw: Int          // Flow.rawValue
    var symptoms: [String]
    var mood: Int             // 0 = unset, 1...5
    var note: String

    init(id: UUID = UUID(), date: Date = .now, flow: Flow = .none,
         symptoms: [String] = [], mood: Int = 0, note: String = "") {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.flowRaw = flow.rawValue
        self.symptoms = symptoms
        self.mood = mood
        self.note = note
    }

    var flow: Flow {
        get { Flow(rawValue: flowRaw) ?? .none }
        set { flowRaw = newValue.rawValue }
    }

    var isEmpty: Bool {
        flow == .none && symptoms.isEmpty && mood == 0 && note.isEmpty
    }
}

enum Flow: Int, CaseIterable, Identifiable {
    case none = 0, spotting, light, medium, heavy
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .spotting: return "Spotting"
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }
    var dots: Int { rawValue }
    var color: Color {
        switch self {
        case .none: return Brand.text3
        case .spotting: return Color(hex: 0xC79AB0)
        case .light: return Color(hex: 0xC57A8E)
        case .medium: return Color(hex: 0xB5556F)
        case .heavy: return Color(hex: 0x8E3A52)
        }
    }
}

/// Predefined symptom catalogue for quick logging.
enum Symptoms {
    static let all: [(String, String)] = [
        ("Cramps", "bolt.fill"),
        ("Headache", "brain.head.profile"),
        ("Bloating", "circle.dashed"),
        ("Tender breasts", "heart.fill"),
        ("Fatigue", "zzz"),
        ("Acne", "drop.fill"),
        ("Backache", "figure.walk"),
        ("Cravings", "fork.knife"),
        ("Nausea", "wind"),
        ("Insomnia", "moon.zzz.fill"),
        ("High energy", "sparkles"),
        ("Calm", "leaf.fill"),
    ]
    static func symbol(for name: String) -> String {
        all.first { $0.0 == name }?.1 ?? "circle.fill"
    }
}
