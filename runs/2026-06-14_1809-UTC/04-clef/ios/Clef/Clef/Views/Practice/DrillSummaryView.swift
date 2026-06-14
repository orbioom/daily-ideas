import SwiftUI

/// End-of-drill summary card: accuracy, avg response time, best streak.
struct DrillSummaryView: View {
    let engine: DrillEngine
    let onAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: badgeSymbol)
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 30)
                    .accessibilityHidden(true)

                Text(headline)
                    .font(Theme.serif(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                if engine.total == 0 {
                    Text("No notes were answered.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    statsGrid
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: "Again", systemImage: "arrow.clockwise", action: onAgain)
                    Button("Done", action: onDone)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
    }

    private var badgeSymbol: String {
        let acc = engine.accuracy
        if acc >= 0.9 { return "star.circle.fill" }
        if acc >= 0.6 { return "hand.thumbsup.circle.fill" }
        return "music.note"
    }

    private var headline: String {
        let acc = engine.accuracy
        if engine.total == 0 { return "Drill ended" }
        if acc >= 0.9 { return "Brilliant reading!" }
        if acc >= 0.6 { return "Nicely done" }
        return "Keep at it"
    }

    private var statsGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 14) {
            tile("\(Int(engine.accuracy * 100))%", "Accuracy", "target")
            tile("\(engine.correct)/\(engine.total)", "Correct", "checkmark.seal.fill")
            tile(avgText, "Avg time", "stopwatch.fill")
            tile("\(engine.bestStreak)", "Best streak", "flame.fill")
        }
    }

    private var avgText: String {
        guard engine.avgMs > 0 else { return "—" }
        return String(format: "%.1fs", engine.avgMs / 1000)
    }

    private func tile(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(Theme.accent)
            Text(value).font(Theme.rounded(24, .bold)).foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
