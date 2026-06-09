import SwiftUI

/// A circular progress ring with a soft track and a gradient fill.
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
                .animation(reduceMotion ? nil : Brand.ease(0.4), value: progress)
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

/// A pill that shows the count of days in a 1-row heatmap-ish strip.
struct MiniHeatStrip: View {
    let values: [Int]            // minutes per day, oldest → newest
    var tint: Color = Brand.live

    private func level(_ v: Int) -> Double {
        guard v > 0 else { return 0 }
        if v >= 30 { return 1.0 }
        if v >= 15 { return 0.7 }
        if v >= 5 { return 0.45 }
        return 0.25
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, v in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(v > 0 ? tint.opacity(0.25 + level(v) * 0.75) : Brand.hairline)
                    .frame(height: 26)
            }
        }
        .accessibilityHidden(true)
    }
}
