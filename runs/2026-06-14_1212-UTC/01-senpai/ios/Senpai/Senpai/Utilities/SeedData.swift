import Foundation
import SwiftData

/// Seeds genres and a realistic 50+ title library with logs.
enum SeedData {

    /// Ensure the standard genre set exists (idempotent).
    @discardableResult
    static func seedGenresIfNeeded(context: ModelContext) -> [String: Genre] {
        var map: [String: Genre] = [:]
        let existing = (try? context.fetch(FetchDescriptor<Genre>())) ?? []
        for g in existing { map[g.name] = g }
        for name in Genre.standardNames where map[name] == nil {
            let g = Genre(name: name)
            context.insert(g)
            map[name] = g
        }
        return map
    }

    /// Seed the full sample library if it hasn't been seeded yet.
    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        seedLibrary(context: context)
        didSeed = true
    }

    /// Build a varied 50+ title library across kinds/statuses/genres with logs.
    static func seedLibrary(context: ModelContext) {
        let genreMap = seedGenresIfNeeded(context: context)
        let catalog = CatalogData.all
        let baseDate = Date()
        let cal = Calendar.current

        // Status mix indexed deterministically so the library exercises every state.
        let statusCycle: [WatchStatus] = [
            .completed, .current, .completed, .planning, .completed,
            .current, .onHold, .completed, .dropped, .current,
            .completed, .planning, .completed, .current, .completed
        ]

        for (i, entry) in catalog.enumerated() {
            let status = statusCycle[i % statusCycle.count]
            let total = entry.defaultUnits
            let score = scoreFor(index: i, status: status)

            let added = baseDate.addingTimeInterval(Double(-(i * 3 + 2)) * 86_400)
            let title = Title(name: entry.name,
                              kind: entry.kind,
                              status: status,
                              totalUnits: total,
                              progress: 0,
                              score: score,
                              favorite: i % 7 == 0,
                              season: entry.season,
                              seasonYear: entry.year,
                              studioOrAuthor: entry.studioOrAuthor,
                              notes: "",
                              addedAt: added)
            context.insert(title)

            // Attach genres.
            for name in entry.genres {
                if let g = genreMap[name] {
                    title.genres.append(g)
                }
            }

            // Set progress + logs per status.
            applyProgress(to: title, status: status, total: total, index: i,
                          startDate: added, calendar: cal)

            // A few rewatches for completed favorites.
            if status == .completed && i % 9 == 0 {
                title.rewatchCount = 1 + (i % 2)
            }
        }

        try? context.save()
    }

    /// Wipe all titles (and cascaded logs); leaves genres intact.
    static func clearTitles(context: ModelContext) {
        if let all = try? context.fetch(FetchDescriptor<Title>()) {
            for t in all { context.delete(t) }
            try? context.save()
        }
    }

    // MARK: Helpers

    private static func scoreFor(index: Int, status: WatchStatus) -> Int {
        switch status {
        case .planning: return 0
        case .dropped: return [4, 5, 3, 6][index % 4]
        case .onHold: return [6, 7, 5][index % 3]
        case .current: return [8, 7, 9, 0][index % 4]
        case .completed: return [9, 8, 10, 7, 9, 8][index % 6]
        }
    }

    private static func applyProgress(to title: Title,
                                      status: WatchStatus,
                                      total: Int,
                                      index: Int,
                                      startDate: Date,
                                      calendar cal: Calendar) {
        switch status {
        case .planning:
            title.progress = 0

        case .completed:
            title.progress = total
            title.startedAt = startDate
            // Spread completions across the trailing year for the month chart.
            let monthsBack = (index % 11) + 1
            title.finishedAt = cal.date(byAdding: .month, value: -monthsBack, to: Date()) ?? startDate
            addLogs(to: title, from: 0, to: total, sessions: 3, anchor: title.finishedAt ?? startDate, cal: cal)

        case .current:
            let done = max(1, min(total - 1, Int(Double(total) * 0.45) + (index % 5)))
            title.progress = done
            title.startedAt = startDate
            addLogs(to: title, from: 0, to: done, sessions: 3, anchor: Date(), cal: cal)

        case .onHold:
            let done = max(1, min(total - 1, total / 4 + (index % 3)))
            title.progress = done
            title.startedAt = startDate
            addLogs(to: title, from: 0, to: done, sessions: 2, anchor: startDate, cal: cal)

        case .dropped:
            let done = max(1, min(total - 1, total / 6 + (index % 2)))
            title.progress = done
            title.startedAt = startDate
            addLogs(to: title, from: 0, to: done, sessions: 1, anchor: startDate, cal: cal)
        }
    }

    /// Split [from, to] into N forward logs ending near `anchor`.
    private static func addLogs(to title: Title, from: Int, to: Int, sessions: Int, anchor: Date, cal: Calendar) {
        guard to > from, sessions > 0 else { return }
        let span = to - from
        let n = min(sessions, span)
        guard n > 0 else { return }
        let step = max(1, span / n)
        var cursor = from
        for s in 0..<n {
            let next = (s == n - 1) ? to : min(to, cursor + step)
            guard next > cursor else { continue }
            let daysBack = (n - s) * 2
            let date = cal.date(byAdding: .day, value: -daysBack, to: anchor) ?? anchor
            let log = WatchLog(date: date, fromUnit: cursor, toUnit: next)
            log.title = title
            title.logs.append(log)
            cursor = next
        }
    }
}
