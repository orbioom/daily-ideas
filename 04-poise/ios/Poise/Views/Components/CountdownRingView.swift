import SwiftUI

struct CountdownRingView: View {
    let progress: Double  // 0.0 to 1.0 (fraction remaining)
    let total: Int
    let remaining: Int
    var ringColor: Color = PoiseTheme.sky
    var size: CGFloat = 160
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(ringColor.opacity(0.2), lineWidth: lineWidth)

            // Progress ring (unfills as time counts down)
            Circle()
                .trim(from: 0, to: max(0, min(1, 1.0 - progress)))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Center content
            VStack(spacing: 4) {
                Text("\(remaining)")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundColor(PoiseTheme.textPrimary)
                Text("seconds")
                    .font(.system(size: size * 0.09))
                    .foregroundColor(PoiseTheme.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct BreakProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < current ? PoiseTheme.sky : PoiseTheme.sky.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
    }
}

struct StreakBadgeView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .foregroundColor(streak > 0 ? .orange : PoiseTheme.textMuted)
            Text("\(streak) day streak")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(streak > 0 ? .orange : PoiseTheme.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(streak > 0 ? Color.orange.opacity(0.12) : PoiseTheme.cardBackground)
        .clipShape(Capsule())
    }
}
