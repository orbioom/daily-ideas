import Foundation
import SwiftData

enum SkillStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "Not Started"
    case learning = "Learning"
    case practicing = "Practicing"
    case comfortable = "Comfortable"
    case mastered = "Mastered"

    var id: String { rawValue }

    var progress: Double {
        switch self {
        case .notStarted: return 0.0
        case .learning: return 0.25
        case .practicing: return 0.5
        case .comfortable: return 0.75
        case .mastered: return 1.0
        }
    }
}

enum SkillCategory: String, Codable, CaseIterable, Identifiable {
    case drawing = "Drawing"
    case painting = "Painting"
    case composition = "Composition"
    case color = "Color Theory"
    case anatomy = "Anatomy"
    case perspective = "Perspective"
    case lighting = "Lighting"
    case texture = "Texture"
    case style = "Style"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .drawing: return "pencil.and.scribble"
        case .painting: return "paintpalette"
        case .composition: return "rectangle.split.3x1"
        case .color: return "circle.hexagongrid"
        case .anatomy: return "figure.stand"
        case .perspective: return "perspective"
        case .lighting: return "sun.max"
        case .texture: return "square.on.square"
        case .style: return "star"
        }
    }
}

@Model
final class ArtSkill {
    var id: UUID = UUID()
    var name: String = ""
    var category: SkillCategory = SkillCategory.drawing
    var status: SkillStatus = SkillStatus.notStarted
    var notes: String = ""
    var targetDate: Date?
    var createdAt: Date = Date.now
    var sessionCount: Int = 0

    init(
        name: String,
        category: SkillCategory = .drawing,
        status: SkillStatus = .notStarted,
        notes: String = "",
        targetDate: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.status = status
        self.notes = notes
        self.targetDate = targetDate
        self.createdAt = .now
        self.sessionCount = 0
    }
}
