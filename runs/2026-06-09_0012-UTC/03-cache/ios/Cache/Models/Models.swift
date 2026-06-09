import Foundation
import SwiftData
import SwiftUI

/// A savings goal. "Saved" is always the sum of its contributions — never a
/// free-floating number — so the math can never drift out of sync.
@Model
final class Goal {
    var name: String
    var targetAmount: Double
    var targetDate: Date?
    var monthlyPlan: Double      // intended contribution per month, 0 = none
    var symbolRaw: String
    var colorRaw: String
    var notes: String
    var isArchived: Bool
    var sortIndex: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Contribution.goal)
    var contributions: [Contribution] = []

    init(name: String,
         targetAmount: Double,
         targetDate: Date? = nil,
         monthlyPlan: Double = 0,
         symbol: GoalSymbol = .star,
         color: GoalColor = .teal,
         notes: String = "",
         sortIndex: Int = 0) {
        self.name = name
        self.targetAmount = max(0, targetAmount)
        self.targetDate = targetDate
        self.monthlyPlan = max(0, monthlyPlan)
        self.symbolRaw = symbol.rawValue
        self.colorRaw = color.rawValue
        self.notes = notes
        self.isArchived = false
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var symbol: GoalSymbol {
        get { GoalSymbol(rawValue: symbolRaw) ?? .star }
        set { symbolRaw = newValue.rawValue }
    }
    var color: GoalColor {
        get { GoalColor(rawValue: colorRaw) ?? .teal }
        set { colorRaw = newValue.rawValue }
    }

    var saved: Double { contributions.reduce(0) { $0 + $1.amount } }
    var remaining: Double { max(0, targetAmount - saved) }
    var progress: Double { targetAmount > 0 ? min(saved / targetAmount, 1) : 0 }
    var isComplete: Bool { saved >= targetAmount && targetAmount > 0 }
}

/// A deposit (or withdrawal, if negative) toward a goal.
@Model
final class Contribution {
    var date: Date
    var amount: Double          // signed: positive deposit, negative withdrawal
    var note: String
    var goal: Goal?

    init(date: Date = .now, amount: Double, note: String = "") {
        self.date = date
        self.amount = (amount * 100).rounded() / 100
        self.note = note
    }

    var isWithdrawal: Bool { amount < 0 }
}

/// Icon choices for a goal.
enum GoalSymbol: String, CaseIterable, Identifiable, Codable {
    case star, house, car, airplane, graduation, gift, heart, umbrella, laptop, camera, ring, leaf
    var id: String { rawValue }
    var systemName: String {
        switch self {
        case .star: return "star.fill"
        case .house: return "house.fill"
        case .car: return "car.fill"
        case .airplane: return "airplane"
        case .graduation: return "graduationcap.fill"
        case .gift: return "gift.fill"
        case .heart: return "heart.fill"
        case .umbrella: return "umbrella.fill"
        case .laptop: return "laptopcomputer"
        case .camera: return "camera.fill"
        case .ring: return "diamond.fill"
        case .leaf: return "leaf.fill"
        }
    }
}

/// Accent colors for a goal.
enum GoalColor: String, CaseIterable, Identifiable, Codable {
    case teal, blue, indigo, plum, rose, amber, sage, slate
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .teal: return Color(hex: 0x4FA8A0)
        case .blue: return Color(hex: 0x5E8FA8)
        case .indigo: return Color(hex: 0x5A6BB0)
        case .plum: return Color(hex: 0x8B6FB0)
        case .rose: return Color(hex: 0xC06A8C)
        case .amber: return Color(hex: 0xC08A4E)
        case .sage: return Color(hex: 0x6E8F5E)
        case .slate: return Color(hex: 0x6E7287)
        }
    }
}
