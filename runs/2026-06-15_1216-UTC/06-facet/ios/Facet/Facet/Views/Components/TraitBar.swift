import SwiftUI

/// A single horizontal trait bar with label, descriptor and (optionally) a percentage.
struct TraitBar: View {
    let traitScore: TraitScore
    var showPercentage: Bool = true
    var animate: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fill: Double = 0

    private var target: Double { max(0, min(100, traitScore.score)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: traitScore.trait.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(traitScore.trait.rawValue)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(showPercentage ? "\(Int(target))%" : traitScore.band.rawValue)
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surfaceAlt)
                    Capsule()
                        .fill(Theme.heroGradient)
                        .frame(width: max(6, geo.size.width * (fill / 100)))
                }
            }
            .frame(height: 10)

            Text(traitScore.descriptor)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
        .onAppear { applyFill() }
        .onChange(of: target) { _, _ in applyFill() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(traitScore.trait.rawValue)
        .accessibilityValue("\(Int(target)) percent, \(traitScore.band.rawValue), \(traitScore.descriptor)")
    }

    private func applyFill() {
        if animate && !reduceMotion {
            withAnimation(.easeOut(duration: 0.7)) { fill = target }
        } else {
            fill = target
        }
    }
}

/// A compact set of mini bars for result cards.
struct MiniTraitBars: View {
    let result: ScoredResult

    var body: some View {
        VStack(spacing: 7) {
            ForEach(result.traitScores) { ts in
                HStack(spacing: 8) {
                    Text(ts.trait.shortLabel)
                        .font(Theme.mono(12, .bold))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(width: 14)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceAlt)
                            Capsule()
                                .fill(Theme.accent)
                                .frame(width: max(4, geo.size.width * (max(0, min(100, ts.score)) / 100)))
                        }
                    }
                    .frame(height: 7)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(ts.trait.rawValue)
                .accessibilityValue("\(Int(ts.score)) percent")
            }
        }
    }
}
