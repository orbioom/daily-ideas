import Foundation
import SwiftData

/// A child. Balance is the sum of their ledger entries — never stored directly.
@Model
final class Kid {
    var name: String
    var colorRaw: String
    var symbol: String
    var weeklyAllowance: Double      // 0 = no automatic allowance
    var lastAllowancePaid: Date?
    var sortIndex: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Chore.kid)
    var chores: [Chore] = []
    @Relationship(deleteRule: .cascade, inverse: \Completion.kid)
    var completions: [Completion] = []
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.kid)
    var ledger: [LedgerEntry] = []

    init(name: String, color: KidColor = .teal, symbol: String = "face.smiling.fill",
         weeklyAllowance: Double = 0, sortIndex: Int = 0) {
        self.name = name
        self.colorRaw = color.rawValue
        self.symbol = symbol
        self.weeklyAllowance = max(0, weeklyAllowance)
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var color: KidColor {
        get { KidColor(rawValue: colorRaw) ?? .teal }
        set { colorRaw = newValue.rawValue }
    }

    /// Money earned from approved chores (rewards are not duplicated in the ledger).
    var earnedFromChores: Double {
        completions.filter { $0.approved }.reduce(0) { $0 + $1.reward }
    }
    /// Spendable balance: chore earnings plus ledger adjustments (allowance,
    /// bonuses, minus payouts and spending).
    var balance: Double { earnedFromChores + ledger.reduce(0) { $0 + $1.amount } }
    var totalPoints: Int { completions.filter { $0.approved }.reduce(0) { $0 + $1.points } }
}

/// A chore. May be assigned to a specific kid (or left for anyone if nil).
@Model
final class Chore {
    var title: String
    var symbol: String
    var reward: Double
    var points: Int
    var repeatRaw: String
    var weekdaysMask: Int        // bit i set => weekday (i+1) selected (1=Sun … 7=Sat)
    var isActive: Bool
    var sortIndex: Int
    var createdAt: Date
    var kid: Kid?

    init(title: String, symbol: String = "checkmark.circle.fill", reward: Double = 0, points: Int = 10,
         repeatType: ChoreRepeat = .daily, weekdaysMask: Int = 0, sortIndex: Int = 0) {
        self.title = title
        self.symbol = symbol
        self.reward = max(0, reward)
        self.points = max(0, points)
        self.repeatRaw = repeatType.rawValue
        self.weekdaysMask = weekdaysMask
        self.isActive = true
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var repeatType: ChoreRepeat {
        get { ChoreRepeat(rawValue: repeatRaw) ?? .daily }
        set { repeatRaw = newValue.rawValue }
    }

    func includes(weekday: Int) -> Bool { weekdaysMask & (1 << (weekday - 1)) != 0 }

    var scheduleSummary: String {
        switch repeatType {
        case .daily: return "Every day"
        case .once: return "One time"
        case .custom:
            let syms = Calendar.current.shortWeekdaySymbols
            let days = (1...7).filter { includes(weekday: $0) }.map { syms[$0 - 1] }
            return days.isEmpty ? "No days set" : days.joined(separator: " ")
        }
    }
}

/// A record that a chore was done. Awaits approval before it pays out.
@Model
final class Completion {
    var date: Date
    var choreTitle: String
    var reward: Double
    var points: Int
    var approved: Bool
    var kid: Kid?
    var chore: Chore?

    init(date: Date = .now, choreTitle: String, reward: Double, points: Int, approved: Bool) {
        self.date = date
        self.choreTitle = choreTitle
        self.reward = reward
        self.points = points
        self.approved = approved
    }
}

/// A signed money movement on a kid's balance.
@Model
final class LedgerEntry {
    var date: Date
    var amount: Double          // signed
    var kindRaw: String
    var note: String
    var kid: Kid?

    init(date: Date = .now, amount: Double, kind: LedgerKind, note: String = "") {
        self.date = date
        self.amount = (amount * 100).rounded() / 100
        self.kindRaw = kind.rawValue
        self.note = note
    }

    var kind: LedgerKind {
        get { LedgerKind(rawValue: kindRaw) ?? .adjustment }
        set { kindRaw = newValue.rawValue }
    }
}
