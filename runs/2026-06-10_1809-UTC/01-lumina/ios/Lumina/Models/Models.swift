import Foundation
import SwiftData
import SwiftUI

/// A single affirmation. Built-in affirmations are seeded once; users can add,
/// favorite, and (for their own) edit or delete their own.
@Model
final class Affirmation {
    var id: UUID
    var text: String
    /// Stored as the raw value of `Theme` so SwiftData persists it simply.
    var themeRaw: String
    var isFavorite: Bool
    var isCustom: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         text: String,
         theme: AffirmationTheme,
         isFavorite: Bool = false,
         isCustom: Bool = false,
         createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.themeRaw = theme.rawValue
        self.isFavorite = isFavorite
        self.isCustom = isCustom
        self.createdAt = createdAt
    }

    var theme: AffirmationTheme {
        get { AffirmationTheme(rawValue: themeRaw) ?? .calm }
        set { themeRaw = newValue.rawValue }
    }
}

/// One calendar day on which the user practiced at least one affirmation.
/// `count` is the number affirmed that day. Used by the streak + insights engine.
@Model
final class DayLog {
    /// Start-of-day, the unique key for a logged day.
    @Attribute(.unique) var day: Date
    var count: Int

    init(day: Date, count: Int = 0) {
        self.day = day
        self.count = count
    }
}

enum AffirmationTheme: String, CaseIterable, Identifiable, Codable {
    case morning, calm, confidence, gratitude, selfLove = "self_love"
    case success, healing, sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .calm: return "Calm"
        case .confidence: return "Confidence"
        case .gratitude: return "Gratitude"
        case .selfLove: return "Self-Love"
        case .success: return "Success"
        case .healing: return "Healing"
        case .sleep: return "Sleep"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sun.horizon"
        case .calm: return "leaf"
        case .confidence: return "bolt.heart"
        case .gratitude: return "hands.sparkles"
        case .selfLove: return "heart"
        case .success: return "flag.checkered"
        case .healing: return "bandage"
        case .sleep: return "moon.stars"
        }
    }

    /// A calm accent hue per theme, resolved per color scheme.
    var tint: Color {
        switch self {
        case .morning: return Brand.dynamic(0xC79A4B, 0xE0C27A)
        case .calm: return Brand.dynamic(0x4FB98C, 0x86C79A)
        case .confidence: return Brand.dynamic(0x9A5BB0, 0xC79AE0)
        case .gratitude: return Brand.dynamic(0xC07A4B, 0xE0A878)
        case .selfLove: return Brand.dynamic(0xC0556E, 0xE08AA0)
        case .success: return Brand.dynamic(0x4E6BA8, 0x8FAEE8)
        case .healing: return Brand.dynamic(0x4F9FB9, 0x86C7D6)
        case .sleep: return Brand.dynamic(0x5B5B99, 0x9A9AD0)
        }
    }
}
