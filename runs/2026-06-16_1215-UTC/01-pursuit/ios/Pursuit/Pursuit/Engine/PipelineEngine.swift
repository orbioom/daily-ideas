import Foundation

/// A single computed metric tile value.
struct RateMetric: Identifiable {
    let id: String
    let title: String
    let value: Double          // 0...1 ratio
    let numerator: Int
    let denominator: Int
    var display: String { Format.percent(value) }
    var subtitle: String { "\(numerator) of \(denominator)" }
}

struct FunnelStageCount: Identifiable {
    var id: String { status.rawValue }
    let status: AppStatus
    let count: Int
}

struct SourceCount: Identifiable {
    var id: String { source.rawValue }
    let source: AppSource
    let count: Int
}

struct StatusSlice: Identifiable {
    var id: String { status.rawValue }
    let status: AppStatus
    let count: Int
}

struct WeekBucket: Identifiable {
    var id: Date { weekStart }
    let weekStart: Date
    let count: Int
    let label: String
}

/// Pure analytics over a set of applications. No SwiftUI, no SwiftData mutation.
/// Every ratio is guarded against division by zero and empty input.
struct PipelineEngine {
    let applications: [Application]
    let weeklyGoal: Int
    let staleAfterDays: Int
    let reference: Date

    private let calendar: Calendar

    init(applications: [Application], weeklyGoal: Int, staleAfterDays: Int, reference: Date = Date()) {
        self.applications = applications
        self.weeklyGoal = max(1, weeklyGoal)
        self.staleAfterDays = max(1, staleAfterDays)
        self.reference = reference
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        self.calendar = cal
    }

    /// Only non-archived applications feed the analytics.
    private var active: [Application] { applications.filter { !$0.isArchived } }

    // MARK: - Counts

    var total: Int { active.count }

    func count(for status: AppStatus) -> Int {
        active.filter { $0.status == status }.count
    }

    /// Applications that have actually been submitted (any status beyond "saved").
    var submittedCount: Int {
        active.filter { $0.status.isSubmitted }.count
    }

    var funnelStageCounts: [FunnelStageCount] {
        AppStatus.funnelStages.map { status in
            // Funnel is cumulative-by-progress: count everyone who reached at least this stage.
            let reached: Int
            switch status {
            case .applied: reached = active.filter { $0.status.isSubmitted }.count
            case .screening: reached = active.filter { $0.status.indicatesResponse }.count
            case .interview: reached = active.filter { $0.status.reachedInterview }.count
            case .offer: reached = active.filter { $0.status.reachedOffer }.count
            case .accepted: reached = active.filter { $0.status == .accepted }.count
            default: reached = count(for: status)
            }
            return FunnelStageCount(status: status, count: reached)
        }
    }

    /// Distribution across every status (for the donut).
    var statusDistribution: [StatusSlice] {
        AppStatus.pipelineOrder.compactMap { status in
            let c = count(for: status)
            return c > 0 ? StatusSlice(status: status, count: c) : nil
        }
    }

    // MARK: - Rates (all guarded)

    private func rate(_ id: String, _ title: String, _ numerator: Int, _ denominator: Int) -> RateMetric {
        let value = denominator > 0 ? Double(numerator) / Double(denominator) : 0
        return RateMetric(id: id, title: title, value: value, numerator: numerator, denominator: denominator)
    }

    var responseRate: RateMetric {
        let responded = active.filter { $0.status.indicatesResponse }.count
        return rate("response", "Response rate", responded, submittedCount)
    }

    var interviewRate: RateMetric {
        let interviewed = active.filter { $0.status.reachedInterview }.count
        return rate("interview", "Interview rate", interviewed, submittedCount)
    }

    var offerRate: RateMetric {
        let offered = active.filter { $0.status.reachedOffer }.count
        return rate("offer", "Offer rate", offered, submittedCount)
    }

    var rateMetrics: [RateMetric] { [responseRate, interviewRate, offerRate] }

    // MARK: - Time to response

    /// Average days from applied date to first recorded response. Nil if no data.
    var averageDaysToResponse: Double? {
        var spans: [Int] = []
        for app in active {
            guard let applied = app.appliedDate, let responded = app.firstResponseDate else { continue }
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: applied),
                                               to: calendar.startOfDay(for: responded)).day ?? 0
            if days >= 0 { spans.append(days) }
        }
        guard !spans.isEmpty else { return nil }
        return Double(spans.reduce(0, +)) / Double(spans.count)
    }

    // MARK: - Cadence vs goal

    var startOfThisWeek: Date {
        calendar.dateInterval(of: .weekOfYear, for: reference)?.start ?? calendar.startOfDay(for: reference)
    }
    var startOfThisMonth: Date {
        calendar.dateInterval(of: .month, for: reference)?.start ?? calendar.startOfDay(for: reference)
    }

    private func appliedDates() -> [Date] {
        active.compactMap { $0.appliedDate }
    }

    var thisWeekCount: Int {
        appliedDates().filter { $0 >= startOfThisWeek && $0 <= reference }.count
    }
    var thisMonthCount: Int {
        appliedDates().filter { $0 >= startOfThisMonth && $0 <= reference }.count
    }

    /// 0...1 progress toward the weekly goal.
    var weeklyGoalProgress: Double {
        min(1, Double(thisWeekCount) / Double(weeklyGoal))
    }

    // MARK: - Weekly bars (last N weeks)

    func weeklyBuckets(weeks: Int = 10) -> [WeekBucket] {
        let n = max(1, weeks)
        let weekStart = startOfThisWeek
        let dates = appliedDates()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        var buckets: [WeekBucket] = []
        for offset in stride(from: n - 1, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: weekStart) else { continue }
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
            let count = dates.filter { $0 >= start && $0 < end }.count
            buckets.append(WeekBucket(weekStart: start, count: count, label: fmt.string(from: start)))
        }
        return buckets
    }

    // MARK: - By source

    var bySource: [SourceCount] {
        AppSource.allCases.compactMap { source in
            let c = active.filter { $0.source == source }.count
            return c > 0 ? SourceCount(source: source, count: c) : nil
        }
        .sorted { $0.count > $1.count }
    }

    // MARK: - Stale / actionable

    /// Applications stuck in "applied" with no activity for N+ days.
    var staleApplications: [Application] {
        let cutoff = calendar.date(byAdding: .day, value: -staleAfterDays, to: reference) ?? reference
        return active.filter { app in
            guard app.status == .applied else { return false }
            let lastActivity = app.events.map(\.date).max() ?? app.dateAdded
            return lastActivity < cutoff
        }
        .sorted { ($0.appliedDate ?? $0.dateAdded) < ($1.appliedDate ?? $1.dateAdded) }
    }

    var upcomingInterviews: [Interview] {
        active
            .flatMap { $0.interviews }
            .filter { $0.isUpcoming }
            .sorted { ($0.scheduledDate ?? .distantFuture) < ($1.scheduledDate ?? .distantFuture) }
    }

    var followUpsDue: [Application] {
        active.filter { app in
            guard app.followUpEnabled, let due = app.followUpDate else { return false }
            return !app.status.isTerminal && due >= calendar.startOfDay(for: reference)
        }
        .sorted { ($0.followUpDate ?? .distantFuture) < ($1.followUpDate ?? .distantFuture) }
    }
}
