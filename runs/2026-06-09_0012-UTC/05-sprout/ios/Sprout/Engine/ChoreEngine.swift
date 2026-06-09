import Foundation
import SwiftData

/// Pure chore-chart logic: what's due today, completion state, allowance, stats.
enum ChoreEngine {

    // MARK: - Scheduling

    static func isDue(_ chore: Chore, on date: Date, calendar: Calendar = .current) -> Bool {
        guard chore.isActive else { return false }
        switch chore.repeatType {
        case .daily: return true
        case .custom: return chore.includes(weekday: calendar.component(.weekday, from: date))
        case .once: return true   // due until completed once (handled by completion check)
        }
    }

    static func isCompleted(_ chore: Chore, by kid: Kid, on date: Date, calendar: Calendar = .current) -> Bool {
        if chore.repeatType == .once {
            return kid.completions.contains { $0.chore?.persistentModelID == chore.persistentModelID }
        }
        return kid.completions.contains {
            $0.chore?.persistentModelID == chore.persistentModelID &&
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    /// Chores assigned to this kid that are scheduled for `date`.
    static func choresFor(_ kid: Kid, on date: Date, calendar: Calendar = .current) -> [Chore] {
        kid.chores.filter { isDue($0, on: date, calendar: calendar) }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    struct TodayItem: Identifiable {
        let id: PersistentIdentifier
        let chore: Chore
        let done: Bool
        let completion: Completion?
    }

    static func todayItems(for kid: Kid, on date: Date = .now, calendar: Calendar = .current) -> [TodayItem] {
        choresFor(kid, on: date, calendar: calendar).map { chore in
            let comp = kid.completions.first {
                $0.chore?.persistentModelID == chore.persistentModelID &&
                (chore.repeatType == .once || calendar.isDate($0.date, inSameDayAs: date))
            }
            return TodayItem(id: chore.persistentModelID, chore: chore, done: comp != nil, completion: comp)
        }
    }

    // MARK: - Approvals

    static func pendingApprovals(_ kids: [Kid]) -> [Completion] {
        kids.flatMap { $0.completions }.filter { !$0.approved }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Allowance auto-credit

    /// Credits any whole weeks of allowance elapsed since the last payment.
    /// Returns the number of kids credited. Mutates `lastAllowancePaid`.
    @discardableResult
    static func creditDueAllowances(_ kids: [Kid], now: Date = .now,
                                    calendar: Calendar = .current, context: ModelContext) -> Int {
        var credited = 0
        for kid in kids where kid.weeklyAllowance > 0 {
            let last = kid.lastAllowancePaid ?? kid.createdAt
            let weeks = (calendar.dateComponents([.weekOfYear], from: last, to: now).weekOfYear) ?? 0
            guard weeks >= 1 else { continue }
            for w in 1...weeks {
                let date = calendar.date(byAdding: .weekOfYear, value: w, to: last) ?? now
                guard date <= now else { break }
                let entry = LedgerEntry(date: date, amount: kid.weeklyAllowance,
                                        kind: .allowance, note: "Weekly allowance")
                entry.kid = kid
                context.insert(entry)
            }
            kid.lastAllowancePaid = calendar.date(byAdding: .weekOfYear, value: weeks, to: last)
            credited += 1
        }
        if credited > 0 { try? context.save() }
        return credited
    }

    // MARK: - Stats

    static func completionsThisWeek(for kid: Kid, now: Date = .now, calendar: Calendar = .current) -> Int {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        return kid.completions.filter { $0.date >= weekStart }.count
    }

    static func earnedThisWeek(for kid: Kid, now: Date = .now, calendar: Calendar = .current) -> Double {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        return kid.ledger.filter { $0.date >= weekStart && $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }

    /// Today's completion ratio across a kid's scheduled chores (0…1).
    static func todayProgress(for kid: Kid, on date: Date = .now) -> Double {
        let items = todayItems(for: kid, on: date)
        guard !items.isEmpty else { return 0 }
        return Double(items.filter { $0.done }.count) / Double(items.count)
    }

    struct DayPoints: Identifiable {
        let id = UUID()
        let day: Date
        let points: Int
    }

    static func dailyPoints(for kid: Kid, days: Int = 14, now: Date = .now, calendar: Calendar = .current) -> [DayPoints] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let pts = kid.completions.filter { $0.approved && calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.points }
            return DayPoints(day: day, points: pts)
        }
    }
}
