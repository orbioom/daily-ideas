import SwiftUI

/// A circular progress ring with a centered label. Used for deck mastery.
struct ProgressRing: View {
    /// 0...1
    let fraction: Double
    var lineWidth: CGFloat = 8
    var tint: Color = Theme.brand
    var label: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: clamped)
            if let label {
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Mastery")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }
}

#Preview {
    ProgressRing(fraction: 0.65, label: "65%")
        .frame(width: 80, height: 80)
        .padding()
}
