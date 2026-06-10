import Foundation
import SwiftData
import SwiftUI

/// A single affirmation. Built-in affirmations are seeded once on first run
/// (isCustom == false); the user can add their own (isCustom == true) and
/// favorite any of them. Favoriting persists on the model itself.
@Model
final class Affirmation {
    var id: UUID
    var text: String
    var categoryRaw: String
    var isCustom: Bool
    var isFavorite: Bool
    var createdAt: Date

    init(id: UUID = UUID(), text: String, category: MantraCategory,
         isCustom: Bool = false, isFavorite: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.categoryRaw = category.rawValue
        self.isCustom = isCustom
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    var category: MantraCategory {
        MantraCategory(rawValue: categoryRaw) ?? .calm
    }
}

/// A logged practice — the user affirmed a line. Snapshots the text so history
/// survives even if the source affirmation is later deleted.
@Model
final class PracticeLog {
    var id: UUID
    var date: Date
    var text: String
    var categoryRaw: String

    init(id: UUID = UUID(), date: Date = .now, text: String, category: MantraCategory) {
        self.id = id
        self.date = date
        self.text = text
        self.categoryRaw = category.rawValue
    }

    var category: MantraCategory {
        MantraCategory(rawValue: categoryRaw) ?? .calm
    }
}

enum MantraCategory: String, CaseIterable, Identifiable, Codable {
    case morning = "Morning"
    case calm = "Calm"
    case confidence = "Confidence"
    case selfLove = "Self-Love"
    case gratitude = "Gratitude"
    case success = "Success"
    case abundance = "Abundance"
    case healing = "Healing"
    case focus = "Focus"
    case sleep = "Sleep"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .calm: return "leaf.fill"
        case .confidence: return "bolt.heart.fill"
        case .selfLove: return "heart.fill"
        case .gratitude: return "hands.sparkles.fill"
        case .success: return "trophy.fill"
        case .abundance: return "sparkles"
        case .healing: return "bandage.fill"
        case .focus: return "scope"
        case .sleep: return "moon.stars.fill"
        }
    }

    /// A calm tint for cards, resolved per color scheme.
    var tint: Color {
        switch self {
        case .morning: return Brand.dynamic(0xC9923E, 0xE7B968)
        case .calm: return Brand.dynamic(0x4FA07C, 0x86C79A)
        case .confidence: return Brand.dynamic(0xB45C7E, 0xE08AAA)
        case .selfLove: return Brand.dynamic(0xC0553E, 0xE08A78)
        case .gratitude: return Brand.dynamic(0x8A6FC0, 0xB59EE8)
        case .success: return Brand.dynamic(0xC09A3E, 0xE0C46A)
        case .abundance: return Brand.dynamic(0x3E9E78, 0x5EF0B0)
        case .healing: return Brand.dynamic(0x4E8AB0, 0x8FBEE8)
        case .focus: return Brand.dynamic(0x5566A8, 0x9AA8E0)
        case .sleep: return Brand.dynamic(0x5A5EA0, 0x9A9EE0)
        }
    }
}
