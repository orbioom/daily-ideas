import SwiftUI

/// Large progress ring used on the Today screen.
struct FastRing: View {
    var progress: Double          // 0...1
    var elapsedLabel: String
    var captionTop: String
    var captionBottom: String
    var overshoot: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.hairline, lineWidth: 18)

            Circle()
                .trim(from: 0, to: max(0.0001, progress))
                .stroke(
                    AngularGradient(
                        colors: overshoot ? [Brand.magic, Brand.live] : [Color(hex: 0xB5552F), Color(hex: 0xE0884F)],
                        center: .center),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.6), value: progress)

            VStack(spacing: 6) {
                Text(captionTop)
                    .font(Brand.mono(12, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(Brand.text3)
                Text(elapsedLabel)
                    .font(Brand.mono(40, weight: .semibold))
                    .foregroundStyle(Brand.text)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(captionBottom)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            .padding(40)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(captionTop). \(elapsedLabel). \(captionBottom)")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

/// Compact labelled metric used across insight cards.
struct StatTile: View {
    var value: String
    var label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct SectionHeader: View {
    let text: String
    var body: some View {
        Eyebrow(text: text)
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
    }
}
