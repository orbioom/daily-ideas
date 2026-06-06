import Foundation
import SwiftData

/// One ordered step in a routine: a kind (prepare/work/rest/cooldown), a duration in
/// seconds, an optional label, and an optional repeat-group membership.
///
/// Repeat groups are expressed by a shared `repeatGroupID` across consecutive segments
/// plus a `repeatCount` (how many times the whole group runs). A standalone segment has
/// `repeatGroupID == nil` and is run exactly once.
@Model
final class Segment {
    var id: UUID
    /// Position within the owning routine (ascending). Kept contiguous by the builder.
    var order: Int
    /// Raw value of `SegmentKind` for tolerant decoding.
    var kindRaw: String
    /// Duration in whole seconds. Always bounded to [1, 3600] by the builder.
    var duration: Int
    /// Optional human label, e.g. "Burpees". Empty string means "use the kind title".
    var label: String
    /// Shared identifier for segments that belong to the same repeat group. nil = standalone.
    var repeatGroupID: UUID?
    /// Number of times the repeat group runs. 1 for standalone segments.
    var repeatCount: Int

    var routine: Routine?

    init(id: UUID = UUID(),
         order: Int,
         kind: SegmentKind,
         duration: Int,
         label: String = "",
         repeatGroupID: UUID? = nil,
         repeatCount: Int = 1) {
        self.id = id
        self.order = order
        self.kindRaw = kind.rawValue
        self.duration = max(1, min(3600, duration))
        self.label = label
        self.repeatGroupID = repeatGroupID
        self.repeatCount = max(1, min(99, repeatCount))
    }

    /// Tolerant accessor — falls back to `.work` for any unknown raw value.
    var kind: SegmentKind {
        get { SegmentKind(rawValue: kindRaw) ?? .work }
        set { kindRaw = newValue.rawValue }
    }

    /// Display label: the custom label if present, otherwise the kind's title.
    var displayLabel: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? kind.title : trimmed
    }

    /// True when this segment is part of a multi-pass repeat group.
    var isInRepeatGroup: Bool { repeatGroupID != nil }
}
