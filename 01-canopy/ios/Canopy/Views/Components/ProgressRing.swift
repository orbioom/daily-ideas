import SwiftUI

struct ProgressRing: View {
    let progress: Double        // 0.0 – can exceed 1.0 (overage)
    let lineWidth: CGFloat
    let diameter: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedProgress: Double = 0

    init(progress: Double, lineWidth: CGFloat = 20, diameter: CGFloat = 200) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.diameter = diameter
    }

    private var clampedProgress: Double {
        min(progress, 1.0)
    }

    private var ringColor: Color {
        CanopyTheme.ringColor(progress: progress)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)

            // Fill
            Circle()
                .trim(from: 0, to: reduceMotion ? clampedProgress : animatedProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            animatedProgress = clampedProgress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = min(newValue, 1.0)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        ProgressRing(progress: 0.35)
        ProgressRing(progress: 0.72)
        ProgressRing(progress: 1.1)
    }
    .padding()
}
