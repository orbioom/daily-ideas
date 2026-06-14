import Foundation

/// The pure counting engine behind Cusp.
///
/// All date math lives here so views stay declarative and the logic is testable.
/// Everything is defensive: invalid dates, leap days, month-end recurrence and
/// negative spans are all handled without crashing.
struct CountdownEngine {

    /// Calendar used for all computations. Honors the user's "week starts on" pref.
    var calendar: Calendar

    init(weekStartsMonday: Bool = false) {
        var cal = Calendar.current
        cal.firstWeekday = weekStartsMonday ? 2 : 1
        self.calendar = cal
    }

    // MARK: - Effective next date

    /// The date this event effectively targets *right now*.
    ///
    /// For non-repeating events this is simply `event.date`. For repeating events
    /// it rolls the stored date forward (or, for "since", finds the most recent
    /// past occurrence) so a yearly birthday always points at the next/most-recent
    /// celebration. Leap-day and month-end safe.
    func effectiveDate(for event: CountdownEvent, now: Date = Date()) -> Date {
        let base = event.date
        guard event.repeatRule.repeats else { return base }

        switch event.kind {
        case .until:
            return nextOccurrence(of: base, rule: event.repeatRule, onOrAfter: now)
        case .since:
            return lastOccurrence(of: base, rule: event.repeatRule, onOrBefore: now)
        }
    }

    /// First occurrence of a recurring date at or after `reference`.
    func nextOccurrence(of base: Date, rule: RepeatRule, onOrAfter reference: Date) -> Date {
        guard rule.repeats else { return base }
        // If the base is already in the future relative to reference, keep it.
        if base >= reference { return base }

        var candidate = base
        var guardCounter = 0
        // Step forward until we pass the reference. Capped to avoid any runaway loop.
        while candidate < reference && guardCounter < 6000 {
            candidate = advance(candidate, by: rule, from: base, steps: guardCounter + 1)
            guardCounter += 1
        }
        return candidate
    }

    /// Most recent occurrence of a recurring date at or before `reference`.
    func lastOccurrence(of base: Date, rule: RepeatRule, onOrBefore reference: Date) -> Date {
        guard rule.repeats else { return base }
        if base > reference {
            // Base is in the future; the "since" anchor is the base itself.
            return base
        }
        // Walk forward to the last occurrence that does not exceed reference.
        var candidate = base
        var previous = base
        var guardCounter = 0
        while candidate <= reference && guardCounter < 6000 {
            previous = candidate
            candidate = advance(candidate, by: rule, from: base, steps: guardCounter + 1)
            guardCounter += 1
        }
        return previous
    }

    /// Advance `base` by `steps` periods of `rule`. Using absolute step count from
    /// the original base keeps month-end and Feb-29 anchored correctly (we never
    /// drift by repeatedly clamping).
    private func advance(_ current: Date, by rule: RepeatRule, from base: Date, steps: Int) -> Date {
        switch rule {
        case .none:
            return current
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: steps, to: base) ?? current
        case .monthly:
            return monthAnchored(base: base, monthsForward: steps)
        case .yearly:
            return yearAnchored(base: base, yearsForward: steps)
        }
    }

    /// Add `monthsForward` months to `base`, clamping the day to the target month's
    /// length (e.g. Jan 31 -> Feb 28/29 -> Mar 31). Preserves time-of-day.
    private func monthAnchored(base: Date, monthsForward: Int) -> Date {
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: base)
        guard let baseDay = comps.day else { return base }
        var target = DateComponents()
        target.year = comps.year
        target.month = (comps.month ?? 1) + monthsForward
        target.day = 1
        target.hour = comps.hour
        target.minute = comps.minute
        target.second = comps.second
        guard let firstOfTarget = calendar.date(from: target) else { return base }
        let maxDay = daysInMonth(of: firstOfTarget)
        let clampedDay = min(baseDay, maxDay)
        // Deterministic: step forward from the 1st by (day - 1) days.
        return calendar.date(byAdding: .day, value: clampedDay - 1, to: firstOfTarget) ?? firstOfTarget
    }

    /// Add `yearsForward` years to `base`, clamping Feb 29 to Feb 28 on common years.
    private func yearAnchored(base: Date, yearsForward: Int) -> Date {
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: base)
        guard let baseDay = comps.day, let baseMonth = comps.month else { return base }
        var target = DateComponents()
        target.year = (comps.year ?? 2000) + yearsForward
        target.month = baseMonth
        target.day = 1
        target.hour = comps.hour
        target.minute = comps.minute
        target.second = comps.second
        guard let firstOfTarget = calendar.date(from: target) else { return base }
        let maxDay = daysInMonth(of: firstOfTarget)
        let clampedDay = min(baseDay, maxDay)
        // Deterministic: step forward from the 1st by (day - 1) days.
        return calendar.date(byAdding: .day, value: clampedDay - 1, to: firstOfTarget) ?? firstOfTarget
    }

    private func daysInMonth(of date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    // MARK: - Remaining / elapsed components

    /// A snapshot of how far away (or how long ago) the effective date is.
    struct Span {
        var days: Int
        var hours: Int
        var minutes: Int
        var seconds: Int
        /// Total whole days (calendar-day granularity), always non-negative.
        var totalDays: Int
        /// True when the effective date is in the future (counting down).
        var isFuture: Bool
        /// True when the effective date falls on today's calendar day.
        var isToday: Bool
    }

    /// Compute the live span between `now` and the event's effective date.
    func span(for event: CountdownEvent, now: Date = Date()) -> Span {
        let target = effectiveDate(for: event, now: now)
        let isToday = calendar.isDate(target, inSameDayAs: now)
        let future = target >= now

        // Fine-grained span for the live ticker (only meaningful when includeTime).
        let from = future ? now : target
        let to = future ? target : now
        let fine = calendar.dateComponents([.day, .hour, .minute, .second], from: from, to: to)

        // Calendar-day count for the headline number.
        let startDay = calendar.startOfDay(for: now)
        let targetDay = calendar.startOfDay(for: target)
        let dayDelta = calendar.dateComponents([.day], from: startDay, to: targetDay).day ?? 0
        let totalDays = abs(dayDelta)

        return Span(
            days: max(0, fine.day ?? 0),
            hours: max(0, fine.hour ?? 0),
            minutes: max(0, fine.minute ?? 0),
            seconds: max(0, fine.second ?? 0),
            totalDays: totalDays,
            isFuture: future,
            isToday: isToday
        )
    }

    /// The big headline number + unit shown on cards. Uses whole-day granularity.
    func headline(for event: CountdownEvent, now: Date = Date()) -> (value: Int, unit: String, caption: String) {
        let s = span(for: event, now: now)
        if s.isToday {
            return (0, "today", event.kind == .until ? "It's happening" : "Happening now")
        }
        let unit = s.totalDays == 1 ? "day" : "days"
        let caption: String
        switch event.kind {
        case .until: caption = s.isFuture ? "to go" : "ago (passed)"
        case .since: caption = "since"
        }
        return (s.totalDays, unit, caption)
    }

    // MARK: - Progress

    /// Fraction 0...1 from `createdAt` to the effective target. For "since" events
    /// the progress measures elapsed time within the current recurrence window.
    func progress(for event: CountdownEvent, now: Date = Date()) -> Double {
        let target = effectiveDate(for: event, now: now)
        let start = min(event.createdAt, target)
        let total = target.timeIntervalSince(start)
        guard total > 0 else { return event.kind == .since ? 1 : (now >= target ? 1 : 0) }
        let elapsed = now.timeIntervalSince(start)
        return min(1, max(0, elapsed / total))
    }

    // MARK: - Grouping & sorting

    enum Group: String, CaseIterable, Identifiable {
        case today = "Today"
        case upcoming = "Upcoming"
        case past = "Past"
        var id: String { rawValue }
    }

    /// Classify an event into Today / Upcoming / Past based on its effective date.
    func group(for event: CountdownEvent, now: Date = Date()) -> Group {
        let target = effectiveDate(for: event, now: now)
        if calendar.isDate(target, inSameDayAs: now) { return .today }
        return target > now ? .upcoming : .past
    }

    /// Sort events for display: soonest-upcoming first, then today, then most-recent past.
    /// Pinned events are surfaced separately by the view, not here.
    func sortedForHome(_ events: [CountdownEvent], now: Date = Date()) -> [CountdownEvent] {
        events.sorted { a, b in
            let ta = effectiveDate(for: a, now: now)
            let tb = effectiveDate(for: b, now: now)
            let ga = group(for: a, now: now)
            let gb = group(for: b, now: now)
            if ga != gb { return groupOrder(ga) < groupOrder(gb) }
            switch ga {
            case .past:
                return ta > tb            // most recent past first
            default:
                return ta < tb            // soonest first
            }
        }
    }

    private func groupOrder(_ g: Group) -> Int {
        switch g {
        case .today: return 0
        case .upcoming: return 1
        case .past: return 2
        }
    }

    // MARK: - Summaries / insights

    /// The next `count` upcoming (or today) events, soonest first.
    func nextEvents(_ events: [CountdownEvent], count: Int = 5, now: Date = Date()) -> [CountdownEvent] {
        let upcoming = events.filter { group(for: $0, now: now) != .past }
        let sorted = upcoming.sorted { effectiveDate(for: $0, now: now) < effectiveDate(for: $1, now: now) }
        return Array(sorted.prefix(max(0, count)))
    }

    /// The month (1...12) with the most effective events, or nil if none upcoming.
    func busiestMonth(_ events: [CountdownEvent], now: Date = Date()) -> (month: Int, count: Int)? {
        var tally: [Int: Int] = [:]
        for e in events {
            let m = calendar.component(.month, from: effectiveDate(for: e, now: now))
            tally[m, default: 0] += 1
        }
        guard let best = tally.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }

    /// Totals for the home header.
    func counts(_ events: [CountdownEvent], now: Date = Date()) -> (upcoming: Int, past: Int, today: Int) {
        var u = 0, p = 0, t = 0
        for e in events {
            switch group(for: e, now: now) {
            case .upcoming: u += 1
            case .past: p += 1
            case .today: t += 1
            }
        }
        return (u, p, t)
    }

    // MARK: - Calendar helpers

    /// All events whose effective date lands on `day`.
    func events(_ events: [CountdownEvent], on day: Date, now: Date = Date()) -> [CountdownEvent] {
        events.filter { calendar.isDate(effectiveDate(for: $0, now: now), inSameDayAs: day) }
    }

    /// The grid of days to render for `month`, padded so each row is a full week
    /// honoring `firstWeekday`. Returns nil-able entries for leading/trailing pads.
    func monthGrid(for month: Date) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstDay = interval.start
        let dayCount = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 30

        let weekday = calendar.component(.weekday, from: firstDay) // 1...7
        let leading = ((weekday - calendar.firstWeekday) + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            if let d = calendar.date(byAdding: .day, value: offset, to: firstDay) {
                cells.append(d)
            }
        }
        // Trailing pad to complete the final week row.
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    /// Localized weekday symbols ordered by `firstWeekday`, short form (e.g. "M","T").
    func orderedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        guard symbols.count == 7 else { return symbols }
        let start = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(start + $0) % 7] }
    }
}
