import SwiftUI

/// A circular progress ring used for overall and per-continent mastery. Respects
/// Reduce Motion (no animated fill when the user prefers reduced motion).
struct MasteryRing: View {
    let progress: Double          // 0...1
    var lineWidth: CGFloat = 10
    var tint: Color = Theme.accent
    var label: String? = nil
    var sublabel: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: clamped)
            VStack(spacing: 2) {
                if let label {
                    Text(label)
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                }
                if let sublabel {
                    Text(sublabel)
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Mastery")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }
}

/// Horizontal labelled progress bar (per-continent rows).
struct MasteryBar: View {
    let title: String
    let progress: Double
    let tint: Color
    var systemImage: String? = nil

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(tint)
                        .frame(width: 18)
                }
                Text(title)
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(Int(clamped * 100))%")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule().fill(tint)
                        .frame(width: max(6, geo.size.width * clamped))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(Int(clamped * 100)) percent mastered")
    }
}
