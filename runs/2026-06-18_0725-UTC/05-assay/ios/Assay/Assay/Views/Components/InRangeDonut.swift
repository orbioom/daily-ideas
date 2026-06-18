import SwiftUI

/// Donut gauge showing optimal / in-range / out-of-range proportions for a
/// panel, with the in-range percentage in the center.
struct InRangeDonut: View {
    let optimal: Int
    let inRange: Int
    let outOfRange: Int
    var lineWidth: CGFloat = 18

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var total: Int { optimal + inRange + outOfRange }

    private var segments: [(fraction: Double, color: Color)] {
        guard total > 0 else { return [] }
        let t = Double(total)
        return [
            (Double(optimal) / t, Theme.good),
            (Double(inRange) / t, Theme.okay),
            (Double(outOfRange) / t, Theme.bad)
        ]
    }

    private var inRangePercent: Int {
        guard total > 0 else { return 0 }
        let frac = Double(optimal + inRange) / Double(total)
        return Int((frac * 100).rounded())
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)

            if total > 0 {
                ForEach(Array(arcs().enumerated()), id: \.offset) { _, arc in
                    Circle()
                        .trim(from: arc.start, to: appeared || reduceMotion ? arc.end : arc.start)
                        .stroke(arc.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }

            VStack(spacing: 2) {
                Text("\(inRangePercent)%")
                    .font(Theme.rounded(34, .bold))
                    .foregroundStyle(Theme.ink)
                Text("in range")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.7)) { appeared = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("In range")
        .accessibilityValue("\(inRangePercent) percent of \(total) markers in range; \(optimal) optimal, \(outOfRange) out of range")
    }

    /// Compute cumulative start/end fractions for each segment.
    private func arcs() -> [(start: Double, end: Double, color: Color)] {
        var acc = 0.0
        var out: [(Double, Double, Color)] = []
        for seg in segments {
            let start = acc
            let end = acc + seg.fraction
            out.append((start, end, seg.color))
            acc = end
        }
        return out.map { (start: $0.0, end: $0.1, color: $0.2) }
    }
}
