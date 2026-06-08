import Foundation

/// Pure skincare logic: product expiry, shelf stats, routine adherence/streaks,
/// and skin-condition trends.
enum SkincareEngine {

    // MARK: - Product expiry

    enum ExpiryState {
        case unopened, fresh, expiringSoon, expired
    }

    struct ExpiryStatus {
        let state: ExpiryState
        let daysRemaining: Int?
        let detail: String
    }

    static func expiry(for product: Product, now: Date = .now,
                       calendar: Calendar = .current, soonDays: Int = 30) -> ExpiryStatus {
        guard let opened = product.openedDate else {
            return ExpiryStatus(state: .unopened, daysRemaining: nil, detail: "Unopened")
        }
        guard let expiry = calendar.date(byAdding: .month, value: product.paoMonths, to: opened) else {
            return ExpiryStatus(state: .fresh, daysRemaining: nil, detail: "Opened")
        }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: expiry)).day ?? 0
        if days < 0 {
            return ExpiryStatus(state: .expired, daysRemaining: days, detail: "Expired \(-days)d ago")
        } else if days <= soonDays {
            return ExpiryStatus(state: .expiringSoon, daysRemaining: days, detail: "Use within \(days)d")
        } else {
            let months = days / 30
            return ExpiryStatus(state: .fresh, daysRemaining: days,
                                detail: months >= 1 ? "Good for ~\(months) mo" : "Good for \(days)d")
        }
    }

    // MARK: - Shelf stats

    struct ShelfStats {
        let total: Int
        let active: Int
        let expiringSoon: Int
        let expired: Int
        let totalValue: Double
    }

    static func shelfStats(_ products: [Product], now: Date = .now) -> ShelfStats {
        let active = products.filter { !$0.isFinished }
        var soon = 0, expired = 0
        for p in active {
            switch expiry(for: p, now: now).state {
            case .expiringSoon: soon += 1
            case .expired: expired += 1
            default: break
            }
        }
        return ShelfStats(total: products.count,
                          active: active.count,
                          expiringSoon: soon,
                          expired: expired,
                          totalValue: active.reduce(0) { $0 + $1.price })
    }

    // MARK: - Routine completion

    /// Active steps for a routine, sorted.
    static func steps(_ all: [RoutineStep], for routine: RoutineKind) -> [RoutineStep] {
        all.filter { $0.routine == routine }.sorted { $0.order < $1.order }
    }

    /// Whether all of a routine's steps are marked done in the given log.
    static func isComplete(routineSteps: [RoutineStep], log: RoutineLog?) -> Bool {
        guard !routineSteps.isEmpty else { return false }
        guard let log else { return false }
        let done = Set(log.doneStepUUIDs)
        return routineSteps.allSatisfy { done.contains($0.uuid) }
    }

    static func completedCount(routineSteps: [RoutineStep], log: RoutineLog?) -> Int {
        guard let log else { return 0 }
        let done = Set(log.doneStepUUIDs)
        return routineSteps.filter { done.contains($0.uuid) }.count
    }

    // MARK: - Streak & adherence

    /// Consecutive days (ending today or yesterday) on which at least one
    /// routine was fully completed.
    static func streak(logs: [RoutineLog], steps: [RoutineStep],
                       now: Date = .now, calendar: Calendar = .current) -> Int {
        // Map day -> did any routine complete that day?
        let logsByDay = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.date) }
        func anyComplete(on day: Date) -> Bool {
            guard let dayLogs = logsByDay[day] else { return false }
            for log in dayLogs {
                let rSteps = SkincareEngine.steps(steps, for: log.routine)
                if isComplete(routineSteps: rSteps, log: log) { return true }
            }
            return false
        }
        var streak = 0
        var day = calendar.startOfDay(for: now)
        // allow the streak to count from yesterday if today not done yet
        if !anyComplete(on: day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var guardCount = 0
        while anyComplete(on: day) && guardCount < 3650 {
            streak += 1
            guardCount += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    /// Completion rate for a routine over the last `days` days (0...1).
    static func adherence(logs: [RoutineLog], steps: [RoutineStep], routine: RoutineKind,
                          days: Int = 14, now: Date = .now, calendar: Calendar = .current) -> Double {
        let rSteps = SkincareEngine.steps(steps, for: routine)
        guard !rSteps.isEmpty else { return 0 }
        let logsByDay = Dictionary(grouping: logs.filter { $0.routine == routine }) {
            calendar.startOfDay(for: $0.date)
        }
        var completedDays = 0
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now)) else { continue }
            if let log = logsByDay[day]?.first, isComplete(routineSteps: rSteps, log: log) {
                completedDays += 1
            }
        }
        return Double(completedDays) / Double(days)
    }

    // MARK: - Skin trend

    struct SkinPoint: Identifiable {
        let id = UUID()
        let date: Date
        let rating: Int
    }

    static func skinTrend(_ logs: [SkinLog], days: Int = 30,
                          now: Date = .now, calendar: Calendar = .current) -> [SkinPoint] {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        return logs.filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
            .map { SkinPoint(date: $0.date, rating: $0.rating) }
    }

    static func concernFrequency(_ logs: [SkinLog], days: Int = 30,
                                 now: Date = .now, calendar: Calendar = .current) -> [(SkinConcern, Int)] {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        var counts: [SkinConcern: Int] = [:]
        for log in logs where log.date >= cutoff {
            for c in log.concerns { counts[c, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }
}
