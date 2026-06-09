import SwiftUI

/// A compact stat/info tile in glass.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
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

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Brand.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A circular progress ring used for the sleep-timer countdown.
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var tint: Color = Brand.magic
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(Brand.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(progress, 1)))
                .stroke(
                    LinearGradient(colors: [tint.opacity(0.6), tint], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.4), value: progress)
        }
        .accessibilityHidden(true)
    }
}

/// A soft, breathing background used on the mixer while sound is playing.
struct AuraBackground: View {
    var active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            Circle()
                .fill(Brand.magic.opacity(active ? 0.10 : 0.04))
                .frame(width: 360, height: 360)
                .blur(radius: 60)
                .scaleEffect(pulse && active && !reduceMotion ? 1.1 : 0.9)
                .offset(y: -120)
                .animation(reduceMotion ? nil : .easeInOut(duration: 6).repeatForever(autoreverses: true),
                           value: pulse)
        }
        .onAppear { pulse = true }
        .accessibilityHidden(true)
    }
}
