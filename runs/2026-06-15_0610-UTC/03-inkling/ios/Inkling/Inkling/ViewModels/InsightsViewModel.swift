import Foundation
import SwiftData

/// Derives ranked correlations from the live trackers. Computation is plain Swift over fetched
/// data (SwiftData predicates can't express Pearson), wrapped in async so the UI can show a brief
/// loading state on large datasets.
@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var results: [CorrelationEngine.Result] = []
    @Published private(set) var isLoading = false
    @Published private(set) var usableFactorCount = 0
    @Published private(set) var usableOutcomeCount = 0

    /// Recompute for the given trackers, time range, and lag. Filtering to the window happens here.
    func recompute(trackers: [Tracker], range: TimeRange, lag: Int) async {
        isLoading = true
        defer { isLoading = false }

        // Build day→value series within the window, active trackers only.
        let cutoff: Date? = range.days.flatMap {
            DayMath.calendar.date(byAdding: .day, value: -($0 - 1), to: DayMath.startOfDay(Date()))
        }

        var series: [CorrelationEngine.Series] = []
        for tracker in trackers where tracker.isActive {
            var byDay: [Date: Double] = [:]
            for entry in tracker.sortedEntries {
                if let cutoff, entry.date < cutoff { continue }
                byDay[DayMath.startOfDay(entry.date)] = entry.value
            }
            guard !byDay.isEmpty else { continue }
            series.append(CorrelationEngine.Series(id: tracker.id,
                                                   name: tracker.name,
                                                   isOutcome: tracker.kind.isOutcome,
                                                   byDay: byDay))
        }

        usableFactorCount = series.filter { !$0.isOutcome }.count
        usableOutcomeCount = series.filter { $0.isOutcome }.count

        // Yield once so SwiftUI can paint the loading state on first compute.
        await Task.yield()
        results = CorrelationEngine.rankedResults(series: series, lag: lag)
    }
}
