import SwiftUI

/// Circular progress ring used in Today view and habit rows.
struct RingProgress: View {
    var progress: Double       // 0.0 … 1.0+
    var color: Color
    var lineWidth: CGFloat = 6
    var size: CGFloat = 36
    var showCheckmark: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }
    private var isComplete: Bool { progress >= 1.0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? .none : Brand.ease(0.5), value: clamped)

            if isComplete && showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundStyle(color)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Large ring used at the top of TodayView.
struct LargeRingProgress: View {
    var completed: Int
    var total: Int
    var color: Color = Brand.live

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 14)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    LinearGradient(colors: [color, color.opacity(0.7)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? .none : Brand.ease(0.6), value: progress)

            VStack(spacing: 2) {
                Text("\(completed)")
                    .font(Brand.mono(34, weight: .bold))
                    .foregroundStyle(Brand.text)
                Text("of \(total)")
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.text2)
            }
        }
        .frame(width: 130, height: 130)
        .accessibilityLabel("\(completed) of \(total) habits completed today")
    }
}
