import Foundation

/// Pure pipeline analytics. No UI, no I/O.
enum FunnelEngine {

    struct FunnelStep: Identifiable {
        let id: Int
        let label: String
        let count: Int
        /// Conversion from the previous step (1.0 for the first step).
        let conversion: Double
    }

    /// Applied → Screening → Interview → Offer counts with step conversions.
    static func funnel(applications: [Application]) -> [FunnelStep] {
        let labels = ["Applied", "Screening", "Interview", "Offer"]
        var counts = [0, 0, 0, 0]
        for app in applications {
            guard let depth = app.maxDepthReached else { continue }
            for d in 0...min(depth, 3) {
                counts[d] += 1
            }
        }
        var steps: [FunnelStep] = []
        for i in 0..<4 {
            let prev = i == 0 ? counts[0] : counts[i - 1]
            let conv = prev > 0 ? Double(counts[i]) / Double(prev) : 0
            steps.append(FunnelStep(id: i, label: labels[i], count: counts[i],
                                    conversion: i == 0 ? 1 : conv))
        }
        return steps
    }

    /// Share of sent applications that got ANY response (moved past applied, or
    /// an explicit rejection — silence and ghosting don't count).
    static func responseRate(applications: [Application]) -> Double? {
        let sent = applications.filter { $0.maxDepthReached != nil || $0.stage == .rejected || $0.stage == .ghosted }
        guard !sent.isEmpty else { return nil }
        let responded = sent.filter { app in
            if let depth = app.maxDepthReached, depth >= 1 { return true }
            return app.stage == .rejected
        }
        return Double(responded.count) / Double(sent.count)
    }

    /// Median days from applying to the first stage movement, over resolved apps.
    static func medianDaysToFirstResponse(applications: [Application]) -> Int? {
        var gaps: [Double] = []
        for app in applications {
            guard let applied = app.appliedDate else { continue }
            let movements = app.events
                .filter { $0.stage != .applied && $0.stage != .wishlist && $0.date > applied }
                .map(\.date)
            if let first = movements.min() {
                gaps.append(first.timeIntervalSince(applied) / 86_400)
            }
        }
        guard !gaps.isEmpty else { return nil }
        let sorted = gaps.sorted()
        return Int(sorted[sorted.count / 2].rounded())
    }

    /// Active applications with no movement for `days` — candidates for a nudge.
    static func stale(applications: [Application], days: Int = 10, now: Date = Date()) -> [Application] {
        applications.filter { app in
            guard !app.stage.isClosed, app.stage != .wishlist else { return false }
            return now.timeIntervalSince(app.lastActivity) > Double(days) * 86_400
        }
        .sorted { $0.lastActivity < $1.lastActivity }
    }

    /// Applications sent per calendar week for the trailing `weeks`.
    static func weeklyApplied(applications: [Application], weeks: Int = 8,
                              calendar: Calendar = .current, now: Date = Date()) -> [(weekStart: Date, count: Int)] {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        var buckets: [Date: Int] = [:]
        var starts: [Date] = []
        for i in 0..<weeks {
            if let start = calendar.date(byAdding: .weekOfYear, value: -i, to: thisWeek) {
                buckets[start] = 0
                starts.append(start)
            }
        }
        for app in applications {
            guard let applied = app.appliedDate,
                  let week = calendar.dateInterval(of: .weekOfYear, for: applied)?.start,
                  buckets[week] != nil else { continue }
            buckets[week, default: 0] += 1
        }
        return starts.sorted().map { (weekStart: $0, count: buckets[$0] ?? 0) }
    }

    static func daysAgoLabel(_ date: Date, now: Date = Date()) -> String {
        let days = Int(now.timeIntervalSince(date) / 86_400)
        if days <= 0 { return "today" }
        if days == 1 { return "yesterday" }
        return "\(days) days ago"
    }
}
