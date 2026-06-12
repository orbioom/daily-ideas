import Foundation
import SwiftData
import SwiftUI

enum Lucidity: Int, Codable, CaseIterable, Identifiable {
    case nonLucid = 0, semiLucid = 1, lucid = 2
    var id: Int { rawValue }
    var label: String {
        switch self { case .nonLucid: return "Not lucid"; case .semiLucid: return "Semi-lucid"; case .lucid: return "Lucid" }
    }
    var symbol: String {
        switch self { case .nonLucid: return "moon.zzz.fill"; case .semiLucid: return "moon.haze.fill"; case .lucid: return "sparkles" }
    }
}

enum DreamMood: String, Codable, CaseIterable, Identifiable {
    case joyful = "Joyful", peaceful = "Peaceful", neutral = "Neutral"
    case strange = "Strange", anxious = "Anxious", scary = "Scary"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .joyful: return "sun.max.fill"
        case .peaceful: return "leaf.fill"
        case .neutral: return "circle.fill"
        case .strange: return "tornado"
        case .anxious: return "wind"
        case .scary: return "exclamationmark.triangle.fill"
        }
    }
    var color: Color {
        switch self {
        case .joyful: return Color(red: 0.97, green: 0.78, blue: 0.36)
        case .peaceful: return Color(red: 0.46, green: 0.78, blue: 0.58)
        case .neutral: return Color(red: 0.60, green: 0.63, blue: 0.72)
        case .strange: return Color(red: 0.66, green: 0.52, blue: 0.86)
        case .anxious: return Color(red: 0.55, green: 0.62, blue: 0.86)
        case .scary: return Color(red: 0.86, green: 0.42, blue: 0.46)
        }
    }
}

enum DreamTechnique: String, Codable, CaseIterable, Identifiable {
    case none = "None", mild = "MILD", wbtb = "WBTB", wild = "WILD"
    case realityCheck = "Reality checks", journaling = "Journaling"
    var id: String { rawValue }
}

@Model
final class Dream {
    @Attribute(.unique) var id: UUID
    /// The night the dream occurred (we key by morning's start-of-day).
    var date: Date
    var title: String
    var narrative: String
    var lucidityRaw: Int
    var vividness: Int            // 1...5
    var moodRaw: String
    var isNightmare: Bool
    var isRecurring: Bool
    var techniqueRaw: String
    var createdAt: Date

    @Relationship(inverse: \DreamSign.dreams)
    var signs: [DreamSign] = []

    init(date: Date = Date(), title: String = "", narrative: String = "",
         lucidity: Lucidity = .nonLucid, vividness: Int = 3, mood: DreamMood = .neutral,
         isNightmare: Bool = false, isRecurring: Bool = false, technique: DreamTechnique = .none) {
        self.id = UUID()
        self.date = date
        self.title = title
        self.narrative = narrative
        self.lucidityRaw = lucidity.rawValue
        self.vividness = vividness
        self.moodRaw = mood.rawValue
        self.isNightmare = isNightmare
        self.isRecurring = isRecurring
        self.techniqueRaw = technique.rawValue
        self.createdAt = Date()
    }

    var lucidity: Lucidity {
        get { Lucidity(rawValue: lucidityRaw) ?? .nonLucid }
        set { lucidityRaw = newValue.rawValue }
    }
    var mood: DreamMood {
        get { DreamMood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }
    var technique: DreamTechnique {
        get { DreamTechnique(rawValue: techniqueRaw) ?? .none }
        set { techniqueRaw = newValue.rawValue }
    }
    var isLucid: Bool { lucidity == .lucid }
    var displayTitle: String { title.isEmpty ? "Untitled dream" : title }
}

enum SignCategory: String, Codable, CaseIterable, Identifiable {
    case person = "Person", place = "Place", action = "Action"
    case theme = "Theme", emotion = "Emotion", object = "Object"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .person: return "person.fill"
        case .place: return "map.fill"
        case .action: return "figure.run"
        case .theme: return "theatermasks.fill"
        case .emotion: return "heart.fill"
        case .object: return "cube.fill"
        }
    }
}

/// A reusable "dream sign" — a recurring person, place, theme or feeling. The
/// frequency across dreams is what makes it useful for lucid-dream training.
@Model
final class DreamSign {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var dreams: [Dream] = []

    init(name: String, category: SignCategory = .theme) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
    }

    var category: SignCategory {
        get { SignCategory(rawValue: categoryRaw) ?? .theme }
        set { categoryRaw = newValue.rawValue }
    }
    var count: Int { dreams.count }
}
