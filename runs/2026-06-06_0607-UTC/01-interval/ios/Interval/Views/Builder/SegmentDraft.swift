import Foundation

/// A mutable value-type representation of a segment used while editing in the builder,
/// so that Cancel can discard cleanly and reordering never touches the live store until
/// Save. Mirrors `Segment` plus a transient grouping flag.
struct SegmentDraft: Identifiable, Equatable {
    let id: UUID
    var kind: SegmentKind
    var duration: Int
    var label: String
    /// Repeat-group membership. Segments sharing this id (and contiguous in the list)
    /// form one group. `nil` means standalone.
    var repeatGroupID: UUID?
    var repeatCount: Int

    init(id: UUID = UUID(),
         kind: SegmentKind,
         duration: Int,
         label: String = "",
         repeatGroupID: UUID? = nil,
         repeatCount: Int = 1) {
        self.id = id
        self.kind = kind
        self.duration = Self.clampDuration(duration)
        self.label = label
        self.repeatGroupID = repeatGroupID
        self.repeatCount = Self.clampCount(repeatCount)
    }

    static func clampDuration(_ value: Int) -> Int { min(3600, max(1, value)) }
    static func clampCount(_ value: Int) -> Int { min(99, max(1, value)) }

    var displayLabel: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? kind.title : trimmed
    }

    var isInRepeatGroup: Bool { repeatGroupID != nil }

    init(from segment: Segment) {
        self.id = segment.id
        self.kind = segment.kind
        self.duration = Self.clampDuration(segment.duration)
        self.label = segment.label
        self.repeatGroupID = segment.repeatGroupID
        self.repeatCount = Self.clampCount(segment.repeatCount)
    }
}

extension Array where Element == SegmentDraft {
    /// Convert drafts to flattened timeline steps for preview, reusing the engine's logic
    /// without needing SwiftData models.
    func flattenedStepCount() -> Int {
        previewSteps().count
    }

    func totalDuration() -> Int {
        previewSteps().reduce(0) { $0 + $1.duration }
    }

    func workDuration() -> Int {
        previewSteps().filter { $0.kind == .work }.reduce(0) { $0 + $1.duration }
    }

    /// Expand drafts the same way `Timeline.flatten` expands segments. Pure, no SwiftData.
    func previewSteps() -> [(kind: SegmentKind, duration: Int)] {
        var steps: [(kind: SegmentKind, duration: Int)] = []
        var index = 0
        while index < count {
            let item = self[index]
            guard let group = item.repeatGroupID else {
                steps.append((item.kind, item.duration))
                index += 1
                continue
            }
            var end = index
            while end < count, self[end].repeatGroupID == group { end += 1 }
            let slice = Array(self[index..<end])
            let passes = Swift.max(1, slice.first?.repeatCount ?? 1)
            for _ in 0..<passes {
                for member in slice { steps.append((member.kind, member.duration)) }
            }
            index = end
        }
        return steps
    }
}
