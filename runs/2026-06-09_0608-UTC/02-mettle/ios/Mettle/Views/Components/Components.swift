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

/// A small rounded badge used for mode / status labels on cards.
struct Pill: View {
    let text: String
    var tint: Color = Brand.text2
    var filled: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(Brand.mono(10, weight: .semibold))
            .tracking(1.0)
            .foregroundStyle(filled ? .white : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)))
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
    }
}
