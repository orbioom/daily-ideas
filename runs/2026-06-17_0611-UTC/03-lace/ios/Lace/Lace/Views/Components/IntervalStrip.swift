import SwiftUI

/// A horizontal, proportional strip visualising a session's intervals.
/// Decorative; an accessibility summary is provided by the caller.
struct IntervalStrip: View {
    let intervals: [Interval]
    var height: CGFloat = 10

    private var total: Int { max(1, intervals.reduce(0) { $0 + $1.durationSeconds }) }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(intervals) { interval in
                    interval.kind.color
                        .frame(width: max(2, geo.size.width * CGFloat(interval.durationSeconds) / CGFloat(total)))
                }
            }
            .clipShape(Capsule(style: .continuous))
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A compact legend of interval kinds present in a session.
struct IntervalLegend: View {
    @Environment(\.colorScheme) private var scheme
    let kinds: [IntervalKind]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(kinds) { kind in
                HStack(spacing: 5) {
                    Circle().fill(kind.color).frame(width: 9, height: 9)
                    Text(kind.title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
