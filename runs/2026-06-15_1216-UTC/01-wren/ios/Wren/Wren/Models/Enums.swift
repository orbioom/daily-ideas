import SwiftUI

// MARK: - Self-care categories

enum GoalCategory: String, CaseIterable, Codable, Identifiable {
    case move = "Move"
    case rest = "Rest"
    case mind = "Mind"
    case connect = "Connect"
    case tidy = "Tidy"
    case nourish = "Nourish"

    var id: String { rawValue }

    var label: String { rawValue }

    var systemImage: String {
        switch self {
        case .move: return "figure.walk"
        case .rest: return "moon.zzz.fill"
        case .mind: return "brain.head.profile"
        case .connect: return "heart.fill"
        case .tidy: return "sparkles"
        case .nourish: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .move: return Color.dyn(0xE07A5B, 0xE8896C)     // coral
        case .rest: return Color.dyn(0x6E84A3, 0x8AA0BE)     // dusk blue
        case .mind: return Color.dyn(0x8A6FA8, 0xA98DC6)     // muted violet
        case .connect: return Color.dyn(0xC2614F, 0xD6826F)  // warm clay
        case .tidy: return Color.dyn(0xD79A4E, 0xE0AC63)     // amber
        case .nourish: return Color.dyn(0x7E9C73, 0x97B488)  // sage
        }
    }
}

// MARK: - Schedule

/// How often a goal is meant to be done. Encoded as a small struct for SwiftData
/// (stored via raw fields on the model) but exposed as a friendly enum.
enum GoalSchedule: Equatable, Hashable {
    case everyDay
    /// Weekday bitmask: bit (weekday-1) set means active. Sunday = bit 0 ... Saturday = bit 6.
    case specificDays(mask: Int)
    case timesPerWeek(Int)

    var summary: String {
        switch self {
        case .everyDay:
            return "Every day"
        case .specificDays(let mask):
            let days = (1...7).compactMap { wd -> String? in
                ((mask >> (wd - 1)) & 1) == 1 ? DateUtils.shortWeekdaySymbol(forWeekday: wd) : nil
            }
            return days.isEmpty ? "No days set" : days.joined(separator: " · ")
        case .timesPerWeek(let n):
            return "\(n)× per week"
        }
    }

    /// Whether this schedule means the goal is "due" on the given date.
    func isDue(on date: Date) -> Bool {
        switch self {
        case .everyDay:
            return true
        case .specificDays(let mask):
            let wd = DateUtils.weekday(date)
            return ((mask >> (wd - 1)) & 1) == 1
        case .timesPerWeek:
            // Times-per-week goals are always offerable; cadence is informational.
            return true
        }
    }
}

// MARK: - Schedule kind (for persistence + editor)

enum ScheduleKind: String, CaseIterable, Codable, Identifiable {
    case everyDay = "Every day"
    case specificDays = "Specific days"
    case timesPerWeek = "Times per week"
    var id: String { rawValue }
}

// MARK: - Journey reward kinds

enum RewardKind: String, Codable, CaseIterable, Identifiable {
    case postcard = "Postcard"
    case cosmetic = "Cosmetic"
    case pebbles = "Pebbles"
    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .postcard: return "photo.on.rectangle.angled"
        case .cosmetic: return "crown.fill"
        case .pebbles: return "circle.grid.2x2.fill"
        }
    }
}

// MARK: - Companion mood

enum CompanionMood: String {
    case thriving = "Thriving"
    case content = "Content"
    case sleepy = "Sleepy"
    case needsYou = "Needs you"

    var systemImage: String {
        switch self {
        case .thriving: return "sun.max.fill"
        case .content: return "leaf.fill"
        case .sleepy: return "moon.zzz.fill"
        case .needsYou: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .thriving: return Theme.good
        case .content: return Theme.accent
        case .sleepy: return Theme.inkSoft
        case .needsYou: return Theme.warn
        }
    }
}

// MARK: - Appearance

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
