import SwiftUI

/// A horizontal stacked bar showing the low / in-range / elevated / high split.
struct TimeInRangeBar: View {
    let slices: [RangeSlice]
    var height: CGFloat = 16

    private var accessibilitySummary: String {
        guard !slices.isEmpty else { return "No readings yet" }
        return slices
            .map { "\($0.band.rawValue) \(Int(($0.pct * 100).rounded())) percent" }
            .joined(separator: ", ")
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                if slices.isEmpty {
                    Rectangle().fill(Theme.surfaceAlt)
                } else {
                    ForEach(slices) { slice in
                        Rectangle()
                            .fill(slice.band.color)
                            .frame(width: max(geo.size.width * slice.pct, slice.pct > 0 ? 2 : 0))
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time in range")
        .accessibilityValue(accessibilitySummary)
    }
}

/// A compact ring showing the in-range percentage.
struct TimeInRangeRing: View {
    let fraction: Double      // 0...1
    var size: CGFloat = 120
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(fraction, 0), 1) }
    private var pctText: String { "\(Int((clamped * 100).rounded()))%" }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceAlt, lineWidth: 12)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(Theme.inRange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: clamped)
            VStack(spacing: 2) {
                Text(pctText)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text("in range")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time in range")
        .accessibilityValue("\(pctText) of readings in target")
    }
}
