import SwiftUI

/// A circular progress ring used for the yearly reading challenge. Shows the
/// fraction complete with a center label (finished / target). Honors Reduce
/// Motion by disabling the fill animation.
struct ChallengeRing: View {
    let fraction: Double      // 0…1
    let finished: Int
    let target: Int
    var lineWidth: CGFloat = 14
    var size: CGFloat = 160

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(colors: [Brand.magic, Brand.live, Brand.magic],
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.6), value: clamped)
            VStack(spacing: 2) {
                Text("\(finished)")
                    .font(Brand.mono(34, weight: .bold))
                    .foregroundStyle(Brand.text)
                Text(target > 0 ? "of \(target)" : "no goal")
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.text2)
                Text("books")
                    .font(Brand.mono(11, weight: .medium))
                    .tracking(1.0)
                    .foregroundStyle(Brand.text3)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Yearly reading challenge")
        .accessibilityValue(target > 0
            ? "\(finished) of \(target) books, \(Format.percent(clamped)) complete"
            : "\(finished) books finished, no goal set")
    }
}
