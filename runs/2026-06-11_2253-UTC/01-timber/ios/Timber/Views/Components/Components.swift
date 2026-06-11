import SwiftUI

/// Big circular Snore Score dial used on summaries and night detail.
struct ScoreDial: View {
    let score: Int
    var size: CGFloat = 160
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animated = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.inkSecondary(scheme).opacity(0.18), lineWidth: 14)
            Circle()
                .trim(from: 0, to: animated ? CGFloat(score) / 100 : 0)
                .stroke(Theme.scoreColor(score),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.inkPrimary(scheme))
                Text("Snore Score")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary(scheme))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if reduceMotion {
                animated = true
            } else {
                withAnimation(.easeOut(duration: 0.9)) { animated = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Snore Score \(score) out of 100")
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Theme.amber)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.inkPrimary(scheme))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var caption: String? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary(scheme))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.inkPrimary(scheme))
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSecondary(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
        .accessibilityElement(children: .combine)
    }
}
