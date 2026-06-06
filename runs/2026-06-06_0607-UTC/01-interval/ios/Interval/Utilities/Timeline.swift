import Foundation

/// One concrete, fully-resolved step on the run timeline. Repeat groups are expanded so
/// every pass is its own `TimelineStep`. This is a pure value type — no SwiftData, no UI —
/// so the engine and previews can reason about a run deterministically.
struct TimelineStep: Identifiable, Equatable {
    let id = UUID()
    let kind: SegmentKind
    let label: String
    /// Duration in whole seconds (>= 1).
    let duration: Int
    /// 1-based pass index within the segment's repeat group (1 when standalone).
    let roundIndex: Int
    /// Total passes for the segment's repeat group (1 when standalone).
    let roundCount: Int

    /// True when this step belongs to a multi-pass repeat group.
    var isRepeated: Bool { roundCount > 1 }

    /// "Burpees" or "Work" plus an optional "3/8" round suffix for repeated steps.
    var headline: String { label }

    /// Compact round annotation, e.g. "Round 3 of 8" (empty when standalone).
    var roundText: String {
        isRepeated ? "Round \(roundIndex) of \(roundCount)" : ""
    }
}

/// Pure timeline flattening: turns an ordered list of `Segment`s — where consecutive
/// segments sharing a `repeatGroupID` form a repeat group run `repeatCount` times — into
/// a flat sequence of `TimelineStep`s.
enum Timeline {

    /// Expand segments (already in `order`) into concrete steps.
    ///
    /// A repeat group is a maximal run of consecutive segments that share the same
    /// non-nil `repeatGroupID`. The whole group repeats `repeatCount` times (taken from
    /// the group's first segment). Standalone segments run exactly once.
    static func flatten(_ segments: [Segment]) -> [TimelineStep] {
        var steps: [TimelineStep] = []
        var index = 0
        let count = segments.count

        while index < count {
            let segment = segments[index]

            guard let groupID = segment.repeatGroupID else {
                // Standalone segment — one pass.
                steps.append(step(from: segment, round: 1, of: 1))
                index += 1
                continue
            }

            // Collect the maximal consecutive run sharing this group id.
            var groupEnd = index
            while groupEnd < count, segments[groupEnd].repeatGroupID == groupID {
                groupEnd += 1
            }
            let groupSlice = Array(segments[index..<groupEnd])
            let passes = max(1, groupSlice.first?.repeatCount ?? 1)

            for pass in 1...passes {
                for member in groupSlice {
                    steps.append(step(from: member, round: pass, of: passes))
                }
            }
            index = groupEnd
        }
        return steps
    }

    private static func step(from segment: Segment, round: Int, of total: Int) -> TimelineStep {
        TimelineStep(
            kind: segment.kind,
            label: segment.displayLabel,
            duration: max(1, segment.duration),
            roundIndex: round,
            roundCount: total
        )
    }
}
