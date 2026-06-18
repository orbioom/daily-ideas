import SwiftUI

/// A horizontal rank ladder with a moving dot showing current progress.
struct RankProgressBar: View {
    let score: Int
    let maxScore: Int
    let reduceMotion: Bool

    private var rank: Rank { RankLadder.rank(score: score, max: maxScore) }
    private var fraction: Double {
        guard maxScore > 0 else { return 0 }
        return min(1, Double(score) / Double(maxScore))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rank.title)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(score) pts")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.hairline)
                        .frame(height: 8)
                    Capsule()
                        .fill(Theme.heroGradient)
                        .frame(width: max(8, width * fraction), height: 8)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: fraction)
                    // Rank tick marks.
                    ForEach(Rank.allCases) { r in
                        Circle()
                            .fill(fraction + 1e-9 >= r.fraction ? Theme.accentDeep : Theme.hairline)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(Theme.bg, lineWidth: 1.5))
                            .offset(x: width * r.fraction - 4.5)
                    }
                }
            }
            .frame(height: 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(rank.title)")
        .accessibilityValue("\(score) of \(maxScore) points, \(Int(fraction * 100)) percent")
    }
}
