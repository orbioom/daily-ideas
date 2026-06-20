import SwiftUI

struct PaceRing: View {
    let progress: Double   // 0.0 to 1.0
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(PaceTheme.accent.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [PaceTheme.accent.opacity(0.7), PaceTheme.accent]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Center text
            Text(String(format: "%.0f%%", min(progress, 1.0) * 100))
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(PaceTheme.accent)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PaceRing(progress: 0.65, size: 100, lineWidth: 12)
        PaceRing(progress: 1.0, size: 80, lineWidth: 10)
        PaceRing(progress: 0.0, size: 80, lineWidth: 10)
    }
    .padding()
}
