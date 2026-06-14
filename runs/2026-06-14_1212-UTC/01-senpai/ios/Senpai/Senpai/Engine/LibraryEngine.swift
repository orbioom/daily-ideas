import Foundation

/// Pure, testable filtering/sorting/derivation over a collection of `Title`s.
/// All operations are deterministic and guarded against empty/nil inputs.
enum LibraryEngine {

    /// Apply kind, status, and search filters, then sort. Pure and order-stable.
    static func filteredAndSorted(_ titles: [Title],
                                  kind: AnimeMediaKind?,
                                  status: WatchStatus?,
                                  search: String,
                                  sort: LibrarySort) -> [Title] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = titles.filter { t in
            if let kind, t.kind != kind { return false }
            if let status, t.status != status { return false }
            if !query.isEmpty {
                let inName = t.name.lowercased().contains(query)
                let inAuthor = t.studioOrAuthor.lowercased().contains(query)
                if !inName && !inAuthor { return false }
            }
            return true
        }
        return sorted(filtered, by: sort)
    }

    /// Sort by the chosen key with a stable name tiebreaker.
    static func sorted(_ titles: [Title], by sort: LibrarySort) -> [Title] {
        switch sort {
        case .recent:
            return titles.sorted { lhs, rhs in
                if lhs.addedAt != rhs.addedAt { return lhs.addedAt > rhs.addedAt }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        case .score:
            return titles.sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        case .title:
            return titles.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .progress:
            return titles.sorted { lhs, rhs in
                if lhs.progressFraction != rhs.progressFraction {
                    return lhs.progressFraction > rhs.progressFraction
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }

    /// Currently-watching/reading titles, ordered by most recent log (then added).
    static func upNext(_ titles: [Title]) -> [Title] {
        titles
            .filter { $0.status == .current }
            .sorted { lhs, rhs in
                let l = lastLogDate(lhs)
                let r = lastLogDate(rhs)
                if l != r { return l > r }
                return lhs.addedAt > rhs.addedAt
            }
    }

    /// Most recently completed titles, newest first (cap supplied by caller).
    static func recentlyCompleted(_ titles: [Title], limit: Int = 12) -> [Title] {
        let completed = titles
            .filter { $0.status == .completed }
            .sorted { lhs, rhs in
                let l = lhs.finishedAt ?? lhs.addedAt
                let r = rhs.finishedAt ?? rhs.addedAt
                if l != r { return l > r }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        return Array(completed.prefix(max(0, limit)))
    }

    /// The date of the most recent log, falling back to the title's added date.
    static func lastLogDate(_ title: Title) -> Date {
        title.logs.map(\.date).max() ?? title.addedAt
    }

    /// Logs for a title sorted newest-first for the history list.
    static func sortedLogs(_ title: Title) -> [WatchLog] {
        title.logs.sorted { $0.date > $1.date }
    }
}
