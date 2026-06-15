import SwiftUI

/// A lightweight, value-type snapshot of how to draw and describe the life grid.
/// Built once per (profile, chapters, milestones, now) change and reused by the Canvas
/// and the popover, so the 4500-cell grid stays cheap to render.
struct GridModel {
    /// One resolved chapter range, pre-mapped to grid indices.
    struct ChapterSpan: Identifiable {
        let id: UUID
        let title: String
        let color: Color
        let startIndex: Int
        let endIndex: Int       // inclusive
        let startDate: Date
        let endDate: Date?
        let note: String?
        var weekCount: Int { max(endIndex - startIndex + 1, 0) }
    }

    let engine: SpanEngine
    let totalWeeks: Int
    let rows: Int
    let columns: Int
    let currentIndex: Int
    /// Per-cell chapter color (nil = no chapter). Indexed by grid index.
    private let cellColors: [Color?]
    /// Set of grid indices that hold a milestone.
    let milestoneIndices: Set<Int>
    let spans: [ChapterSpan]

    init(engine: SpanEngine,
         chapters: [Chapter],
         milestones: [LifeMilestone],
         palette: Palette,
         now: Date = Date()) {
        self.engine = engine
        let total = max(engine.totalWeeks, 1)
        self.totalWeeks = total
        self.rows = engine.rows
        self.columns = SpanEngine.weeksPerYear
        self.currentIndex = engine.currentWeekIndex(now: now)

        // Build chapter spans, sorted by start so most-recent start wins on overlap.
        var built: [ChapterSpan] = []
        let sortedChapters = chapters.sorted { lhs, rhs in
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.sortOrder < rhs.sortOrder
        }
        for ch in sortedChapters {
            let rawStart = engine.weekIndex(for: ch.startDate)
            let endDate = ch.endDate ?? now
            let rawEnd = engine.weekIndex(for: endDate)
            let start = min(max(rawStart, 0), total - 1)
            let end = min(max(rawEnd, start), total - 1)
            guard rawEnd >= 0 else { continue }   // entirely before birth → skip
            built.append(ChapterSpan(id: ch.id,
                                     title: ch.title,
                                     color: Color(hexString: ch.colorHex, fallback: palette.color(built.count)),
                                     startIndex: start,
                                     endIndex: end,
                                     startDate: ch.startDate,
                                     endDate: ch.endDate,
                                     note: ch.note))
        }
        self.spans = built

        // Paint cells. Later (more-recent start) chapters overwrite earlier ones on overlap.
        var colors = [Color?](repeating: nil, count: total)
        for span in built {
            guard span.startIndex <= span.endIndex else { continue }
            for i in span.startIndex...span.endIndex where i >= 0 && i < total {
                colors[i] = span.color
            }
        }
        self.cellColors = colors

        // Milestone indices.
        var mi = Set<Int>()
        for m in milestones {
            if let idx = engine.gridIndex(for: m.date) { mi.insert(idx) }
        }
        self.milestoneIndices = mi
    }

    func chapterColor(at index: Int) -> Color? {
        guard index >= 0 && index < cellColors.count else { return nil }
        return cellColors[index]
    }

    func hasMilestone(at index: Int) -> Bool {
        milestoneIndices.contains(index)
    }

    /// The chapter span covering a given index (most-recent start wins), if any.
    func span(at index: Int) -> ChapterSpan? {
        var match: ChapterSpan?
        for span in spans where index >= span.startIndex && index <= span.endIndex {
            match = span    // later in array = more recent start
        }
        return match
    }
}
