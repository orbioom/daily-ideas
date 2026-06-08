import Foundation
import SwiftData

/// Pure scheduling logic over a day's blocks: timeline column packing,
/// conflict detection, free-gap finding, and day/category statistics.
/// No SwiftUI, no SwiftData — fully unit-testable.
enum ScheduleEngine {

    // MARK: - Timeline layout

    /// A block placed into a column so overlapping blocks render side by side.
    struct Placed: Identifiable {
        let id: PersistentID
        let block: TimeBlock
        let column: Int
        let columnCount: Int
    }

    /// Assign each block a column index and the number of columns in its
    /// overlap cluster (interval-partitioning). Blocks must be for one day.
    static func layout(_ blocks: [TimeBlock]) -> [Placed] {
        let sorted = blocks.sorted {
            $0.startMinuteOfDay != $1.startMinuteOfDay
                ? $0.startMinuteOfDay < $1.startMinuteOfDay
                : $0.durationMinutes > $1.durationMinutes
        }
        var result: [Placed] = []
        var cluster: [(block: TimeBlock, column: Int)] = []
        var columnEnds: [Int] = []   // end-minute of last block in each column
        var clusterMaxEnd = Int.min

        func flush() {
            let count = max(columnEnds.count, 1)
            for entry in cluster {
                result.append(Placed(id: entry.block.persistentModelID,
                                     block: entry.block,
                                     column: entry.column,
                                     columnCount: count))
            }
            cluster.removeAll()
            columnEnds.removeAll()
            clusterMaxEnd = Int.min
        }

        for block in sorted {
            if !cluster.isEmpty && block.startMinuteOfDay >= clusterMaxEnd {
                flush()
            }
            // find first column that is free at this start
            var assigned: Int? = nil
            for (i, end) in columnEnds.enumerated() where block.startMinuteOfDay >= end {
                assigned = i
                columnEnds[i] = block.endMinuteOfDay
                break
            }
            if assigned == nil {
                columnEnds.append(block.endMinuteOfDay)
                assigned = columnEnds.count - 1
            }
            cluster.append((block, assigned ?? 0))
            clusterMaxEnd = max(clusterMaxEnd, block.endMinuteOfDay)
        }
        flush()
        return result
    }

    // MARK: - Conflicts

    /// Pairs of blocks whose times overlap (same day).
    static func conflicts(_ blocks: [TimeBlock]) -> Int {
        let sorted = blocks.sorted { $0.startMinuteOfDay < $1.startMinuteOfDay }
        var count = 0
        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                if sorted[j].startMinuteOfDay < sorted[i].endMinuteOfDay {
                    count += 1
                } else {
                    break
                }
            }
        }
        return count
    }

    // MARK: - Free gaps

    struct Gap: Identifiable {
        let id = UUID()
        let startMinute: Int
        let endMinute: Int
        var minutes: Int { endMinute - startMinute }
    }

    /// Free windows between blocks inside the waking window [dayStart, dayEnd]
    /// (minutes of day). Only gaps of at least `minMinutes` are returned.
    static func freeGaps(_ blocks: [TimeBlock],
                         dayStart: Int,
                         dayEnd: Int,
                         minMinutes: Int = 30) -> [Gap] {
        let intervals = blocks
            .map { (max($0.startMinuteOfDay, dayStart), min($0.endMinuteOfDay, dayEnd)) }
            .filter { $0.0 < $0.1 }
            .sorted { $0.0 < $1.0 }
        var gaps: [Gap] = []
        var cursor = dayStart
        for (s, e) in intervals {
            if s - cursor >= minMinutes {
                gaps.append(Gap(startMinute: cursor, endMinute: s))
            }
            cursor = max(cursor, e)
        }
        if dayEnd - cursor >= minMinutes {
            gaps.append(Gap(startMinute: cursor, endMinute: dayEnd))
        }
        return gaps
    }

    // MARK: - Day summary

    struct DaySummary {
        var scheduledMinutes: Int
        var doneMinutes: Int
        var freeMinutes: Int
        var blockCount: Int
        var conflicts: Int
        var completion: Double   // 0...1 of scheduled minutes done
    }

    static func summary(_ blocks: [TimeBlock],
                        dayStart: Int,
                        dayEnd: Int) -> DaySummary {
        let scheduled = blocks.reduce(0) { $0 + $1.durationMinutes }
        let done = blocks.filter { $0.isDone }.reduce(0) { $0 + $1.durationMinutes }
        let free = freeGaps(blocks, dayStart: dayStart, dayEnd: dayEnd, minMinutes: 1)
            .reduce(0) { $0 + $1.minutes }
        let completion = scheduled > 0 ? Double(done) / Double(scheduled) : 0
        return DaySummary(scheduledMinutes: scheduled,
                          doneMinutes: done,
                          freeMinutes: free,
                          blockCount: blocks.count,
                          conflicts: conflicts(blocks),
                          completion: completion)
    }

    // MARK: - Category breakdown

    struct CategorySlice: Identifiable {
        var id: String { category.rawValue }
        let category: BlockCategory
        let minutes: Int
    }

    static func categoryBreakdown(_ blocks: [TimeBlock]) -> [CategorySlice] {
        var totals: [BlockCategory: Int] = [:]
        for b in blocks { totals[b.category, default: 0] += b.durationMinutes }
        return totals
            .map { CategorySlice(category: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }
    }

    // MARK: - Next up

    /// The next not-done block starting at or after `now` (same day).
    static func nextUp(_ blocks: [TimeBlock], now: Date) -> TimeBlock? {
        blocks
            .filter { !$0.isDone && $0.start >= now }
            .min { $0.start < $1.start }
    }

    // MARK: - Formatting helpers

    static func clockString(minuteOfDay: Int) -> String {
        let m = ((minuteOfDay % 1440) + 1440) % 1440
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date())
        let date = cal.date(byAdding: .minute, value: m, to: base) ?? base
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    static func durationString(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}

typealias PersistentID = PersistentIdentifier
