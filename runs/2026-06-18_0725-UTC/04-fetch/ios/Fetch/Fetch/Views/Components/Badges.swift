import SwiftUI

/// Difficulty shown as 1...4 filled dots.
struct DifficultyDots: View {
    let difficulty: Difficulty
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...4, id: \.self) { i in
                Circle()
                    .fill(i <= difficulty.rawValue ? difficulty.color : Theme.hairline)
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Difficulty \(difficulty.label)")
    }
}

/// A status badge for a trick (Not Started / Learning / Practicing / Mastered).
struct StatusBadge: View {
    let status: TrickStatus
    var compact: Bool = false

    private var color: Color {
        switch status {
        case .notStarted: return Theme.inkSoft
        case .learning: return Theme.warn
        case .practicing: return Theme.accent
        case .mastered: return Theme.good
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 11, weight: .bold))
            if !compact {
                Text(status.rawValue)
                    .font(Theme.rounded(12, .semibold))
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, compact ? 7 : 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.14)))
        .accessibilityLabel("Status: \(status.rawValue)")
    }
}

/// A circular progress ring used for mastery / program progress.
struct ProgressRing: View {
    let fraction: Double
    var size: CGFloat = 64
    var lineWidth: CGFloat = 8
    var tint: Color = Theme.accent
    var label: String? = nil

    private var clamped: Double { min(1, max(0, fraction)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let label {
                Text(label)
                    .font(Theme.rounded(size * 0.26, .bold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(label.map { "Progress \($0)" } ?? "Progress \(Int(clamped * 100)) percent")
    }
}
