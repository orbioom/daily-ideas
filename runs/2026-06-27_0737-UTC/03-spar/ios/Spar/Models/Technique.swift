import SwiftData
import Foundation

enum TechniqueCategory: String, CaseIterable, Codable {
    case punch = "Punches"
    case kick = "Kicks"
    case elbow = "Elbows"
    case knee = "Knees"
    case defense = "Defense"
    case footwork = "Footwork"
    case clinch = "Clinch"
    case combo = "Combinations"

    var icon: String {
        switch self {
        case .punch: return "hand.raised.fingers.spread.fill"
        case .kick: return "figure.kickboxing"
        case .elbow: return "figure.arms.open"
        case .knee: return "figure.walk"
        case .defense: return "shield.fill"
        case .footwork: return "figure.walk.circle.fill"
        case .clinch: return "hands.and.sparkles.fill"
        case .combo: return "arrow.triangle.turn.up.right.diamond.fill"
        }
    }
}

enum MasteryLevel: Int, CaseIterable, Codable {
    case learning = 1, developing, competent, proficient, mastered

    var label: String {
        switch self {
        case .learning: return "Learning"
        case .developing: return "Developing"
        case .competent: return "Competent"
        case .proficient: return "Proficient"
        case .mastered: return "Mastered"
        }
    }

    var color: String {
        switch self {
        case .learning: return "gray"
        case .developing: return "blue"
        case .competent: return "green"
        case .proficient: return "orange"
        case .mastered: return "gold"
        }
    }
}

@Model
final class Technique {
    var id: UUID
    var name: String
    var categoryRaw: String
    var details: String
    var masteryRaw: Int
    var practiceCount: Int
    var lastPracticed: Date?
    var isFavorite: Bool
    var isCustom: Bool

    init(
        name: String,
        category: TechniqueCategory,
        details: String = "",
        mastery: MasteryLevel = .learning,
        practiceCount: Int = 0,
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.details = details
        self.masteryRaw = mastery.rawValue
        self.practiceCount = practiceCount
        self.isFavorite = false
        self.isCustom = isCustom
    }

    var category: TechniqueCategory {
        get { TechniqueCategory(rawValue: categoryRaw) ?? .punch }
        set { categoryRaw = newValue.rawValue }
    }

    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryRaw) ?? .learning }
        set { masteryRaw = newValue.rawValue }
    }
}
