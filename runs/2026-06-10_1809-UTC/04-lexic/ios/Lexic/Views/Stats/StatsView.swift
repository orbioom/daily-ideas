import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var games: [WordGame]

    private var stats: LexicStats { StatsEngine.stats(games) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if stats.played == 0 {
                    EmptyStateView(icon: "chart.bar",
                                   title: "No games yet",
                                   message: "Play the daily word or a practice round to start tracking your streak and guess distribution.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(stats.played)", label: "Played")
                                StatTile(value: "\(Int(stats.winRate * 100))%", label: "Win rate")
                            }
                            HStack(spacing: 12) {
                                StatTile(value: "\(stats.currentStreak)", label: "Streak", tint: Brand.magic)
                                StatTile(value: "\(stats.maxStreak)", label: "Max streak")
                            }
                            distributionCard
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guess distribution").font(.headline).foregroundStyle(Brand.text)
            ForEach(0..<6, id: \.self) { i in
                let count = stats.distribution[i]
                HStack(spacing: 10) {
                    Text("\(i + 1)")
                        .font(Brand.mono(14, weight: .semibold))
                        .foregroundStyle(Brand.text2).frame(width: 16)
                    GeometryReader { geo in
                        let frac = stats.maxBar > 0 ? CGFloat(count) / CGFloat(stats.maxBar) : 0
                        let w = max(count > 0 ? 28 : 0, geo.size.width * frac)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5).fill(Brand.hairline.opacity(0.3))
                                .frame(height: 26)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(LetterState.correct.tint)
                                .frame(width: w, height: 26)
                            Text("\(count)")
                                .font(Brand.mono(13, weight: .bold)).foregroundStyle(.white)
                                .padding(.leading, 8)
                                .opacity(count > 0 ? 1 : 0)
                        }
                    }
                    .frame(height: 26)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(i + 1) guesses: \(count) wins")
            }
        }
        .padding(18).glassCard()
    }
}

#Preview {
    StatsView().modelContainer(for: WordGame.self, inMemory: true)
}
