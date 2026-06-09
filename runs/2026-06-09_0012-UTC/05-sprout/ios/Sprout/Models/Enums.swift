import SwiftUI

/// How often a chore recurs.
enum ChoreRepeat: String, CaseIterable, Identifiable, Codable {
    case daily, custom, once
    var id: String { rawValue }
    var title: String {
        switch self {
        case .daily: return "Every day"
        case .custom: return "Certain days"
        case .once: return "One time"
        }
    }
}

/// A ledger movement's reason.
enum LedgerKind: String, CaseIterable, Identifiable, Codable {
    case bonus, allowance, payout, spend, adjustment
    var id: String { rawValue }
    var title: String {
        switch self {
        case .bonus: return "Bonus"
        case .allowance: return "Allowance"
        case .payout: return "Cashed out"
        case .spend: return "Spent"
        case .adjustment: return "Adjustment"
        }
    }
    var icon: String {
        switch self {
        case .bonus: return "star.fill"
        case .allowance: return "calendar.badge.clock"
        case .payout: return "banknote.fill"
        case .spend: return "cart.fill"
        case .adjustment: return "slider.horizontal.3"
        }
    }
}

/// Avatar accent colors for a child.
enum KidColor: String, CaseIterable, Identifiable, Codable {
    case teal, blue, indigo, plum, rose, amber, green, slate
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .teal: return Color(hex: 0x4FA8A0)
        case .blue: return Color(hex: 0x5E8FA8)
        case .indigo: return Color(hex: 0x5A6BB0)
        case .plum: return Color(hex: 0x8B6FB0)
        case .rose: return Color(hex: 0xC06A8C)
        case .amber: return Color(hex: 0xC08A4E)
        case .green: return Color(hex: 0x6E9E4E)
        case .slate: return Color(hex: 0x6E7287)
        }
    }
}

/// Symbols available for chores and kids.
enum Glyph {
    static let chores = ["bed.double.fill", "trash.fill", "fork.knife", "dog.fill", "cat.fill",
                         "leaf.fill", "book.fill", "tshirt.fill", "shower.fill", "cup.and.saucer.fill",
                         "sparkles", "wrench.fill", "pencil", "cart.fill", "hands.and.sparkles.fill",
                         "toothbrush", "washer.fill", "car.fill", "tray.full.fill", "plus.circle.fill"]
    static let kids = ["face.smiling.fill", "star.fill", "bolt.fill", "heart.fill", "leaf.fill",
                       "tortoise.fill", "hare.fill", "bird.fill", "ant.fill", "fish.fill"]
}
