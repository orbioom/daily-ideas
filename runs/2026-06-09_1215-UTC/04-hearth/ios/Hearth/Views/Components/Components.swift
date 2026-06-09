import SwiftUI

/// A circular progress ring with a soft track and a gradient fill.
/// Used for the home cleanliness gauge and room freshness rings.
struct ProgressRing: View {
    var progress: Double          // 0…1
    var lineWidth: CGFloat = 14
    var tint: Color = Brand.live
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(progress, 1)))
                .stroke(
                    LinearGradient(colors: [tint.opacity(0.6), tint],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.5), value: progress)
        }
        .accessibilityHidden(true)
    }
}

/// A compact glass stat tile: a big mono value over a label.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Brand.mono(24, weight: .semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(11, weight: .medium))
                .tracking(1.1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A small section title used above grouped content.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Brand.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A slim horizontal freshness bar (0…1) that shifts from danger to live as the
/// score climbs. Decorative — callers supply the accessibility label.
struct FreshnessBar: View {
    var value: Double
    var tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline)
                Capsule()
                    .fill(tint.opacity(0.85))
                    .frame(width: max(4, geo.size.width * CGFloat(min(1, max(0, value)))))
                    .animation(reduceMotion ? nil : Brand.ease(0.4), value: value)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

/// A small pill that shows a `DueStatus` with its dot, label, and tint.
struct StatusPill: View {
    let status: HearthEngine.DueStatus
    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: status.color)
            Text(status.label)
                .font(Brand.mono(12, weight: .medium))
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.label)
    }
}
