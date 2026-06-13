import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var records: [GameRecord]
    private var summary: StatsSummary { StatsSummary.from(records) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if summary.played == 0 {
                    EmptyState(icon: "chart.bar",
                               title: "No stats yet",
                               message: "Play the daily puzzle and your win rate, streaks, and guess distribution will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statsRow
                            distributionCard
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Statistics")
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            tile("\(summary.played)", "Played")
            tile("\(summary.winPercent)", "Win %")
            tile("\(summary.currentStreak)", "Streak")
            tile("\(summary.maxStreak)", "Best")
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.rounded(26)).foregroundStyle(Theme.ink)
            Text(label.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(0.4)
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .accessibilityElement(children: .combine).accessibilityLabel("\(value) \(label)")
    }

    private var distributionCard: some View {
        let dist = summary.distribution
        let maxVal = max(1, dist.max() ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Guess distribution").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
            ForEach(0..<WordGame.maxRows, id: \.self) { i in
                HStack(spacing: 10) {
                    Text("\(i + 1)").font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.inkSoft).frame(width: 16)
                    GeometryReader { geo in
                        let w = max(28, geo.size.width * CGFloat(dist[i]) / CGFloat(maxVal))
                        ZStack(alignment: .trailing) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(dist[i] > 0 ? Theme.correct : Theme.surfaceAlt)
                                .frame(width: dist[i] > 0 ? w : 28)
                            Text("\(dist[i])").font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(dist[i] > 0 ? .white : Theme.inkFaint)
                                .padding(.trailing, 8)
                        }
                    }
                    .frame(height: 26)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(dist[i]) games solved in \(i + 1)")
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
    }
}
