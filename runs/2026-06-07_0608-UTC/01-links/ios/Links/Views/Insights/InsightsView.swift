import SwiftUI
import SwiftData

/// Aggregate stats across all complete rounds: scoring average, best round,
/// accuracy, and a scoring distribution.
struct InsightsView: View {
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]

    private var complete: [Round] { rounds.filter { $0.isComplete } }

    var body: some View {
        NavigationStack {
            Group {
                if complete.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "chart.bar.xaxis", title: "No stats yet",
                                       message: "Complete a round to start seeing your scoring trends.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            overviewCard
                            accuracyCard
                            distributionCard
                            byParCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
            .background(Brand.pageBackground)
        }
    }

    private var avgScore: Double {
        let totals = complete.map { Double($0.totalScore) }
        return totals.isEmpty ? 0 : totals.reduce(0, +) / Double(totals.count)
    }
    private var avgToPar: Double {
        let v = complete.map { Double($0.toPar) }
        return v.isEmpty ? 0 : v.reduce(0, +) / Double(v.count)
    }
    private var best: Round? { complete.min { $0.toPar < $1.toPar } }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Scoring")
            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                StatTile(value: String(format: "%.1f", avgScore), label: "Avg score")
                StatTile(value: toParText(Int(avgToPar.rounded())), label: "Avg to par",
                         accent: avgToPar <= 0 ? Brand.live : Brand.text)
                StatTile(value: best.map { "\($0.totalScore)" } ?? "—", label: "Best round")
                StatTile(value: "\(complete.count)", label: "Rounds")
            }
            if let best {
                Text("Best: \(best.courseName) · \(toParText(best.toPar)) · \(best.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    private var accuracyCard: some View {
        let firOpp = complete.map { $0.fairwayOpportunities }.reduce(0, +)
        let firHit = complete.map { $0.fairwaysHitCount }.reduce(0, +)
        let girTotal = complete.map { $0.holeCount }.reduce(0, +)
        let girHit = complete.map { $0.girCount }.reduce(0, +)
        let puttRounds = complete.filter { $0.totalPutts > 0 }
        let avgPutts = puttRounds.isEmpty ? 0 :
            Double(puttRounds.map { $0.totalPutts }.reduce(0, +)) / Double(puttRounds.count)
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Accuracy")
            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                StatTile(value: firOpp > 0 ? "\(Int(Double(firHit)/Double(firOpp)*100))%" : "—", label: "Fairways")
                StatTile(value: girTotal > 0 ? "\(Int(Double(girHit)/Double(girTotal)*100))%" : "—", label: "Greens")
                StatTile(value: avgPutts > 0 ? String(format: "%.1f", avgPutts) : "—", label: "Putts/rd")
            }
        }
        .glassCard()
    }

    private var distribution: [(String, Int, Color)] {
        var eagle = 0, birdie = 0, par = 0, bogey = 0, dbl = 0
        for r in complete {
            for i in r.holePars.indices where r.holeScores[i] > 0 {
                switch r.holeScores[i] - r.holePars[i] {
                case ..<(-1): eagle += 1
                case -1: birdie += 1
                case 0: par += 1
                case 1: bogey += 1
                default: dbl += 1
                }
            }
        }
        return [("Eagle+", eagle, Brand.magic), ("Birdie", birdie, Brand.live),
                ("Par", par, Brand.text), ("Bogey", bogey, Brand.warn),
                ("Double+", dbl, Brand.danger)]
    }

    private var distributionCard: some View {
        let dist = distribution
        let total = max(1, dist.map { $0.1 }.reduce(0, +))
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Scoring distribution")
            ForEach(dist, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.0).font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(item.1)  ·  \(Int(Double(item.1)/Double(total)*100))%")
                            .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Brand.hairline).frame(height: 8)
                            Capsule().fill(item.2)
                                .frame(width: geo.size.width * Double(item.1) / Double(total), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.0): \(item.1) holes")
            }
        }
        .glassCard()
    }

    private var byParCard: some View {
        var sums: [Int: (over: Int, count: Int)] = [3: (0,0), 4: (0,0), 5: (0,0)]
        for r in complete {
            for i in r.holePars.indices where r.holeScores[i] > 0 {
                let p = r.holePars[i]
                if sums[p] != nil {
                    sums[p]!.over += r.holeScores[i] - p
                    sums[p]!.count += 1
                }
            }
        }
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Average vs par by hole type")
            ForEach([3, 4, 5], id: \.self) { p in
                let s = sums[p] ?? (0, 0)
                HStack {
                    Text("Par \(p)").foregroundStyle(Brand.text2)
                    Spacer()
                    if s.count > 0 {
                        let avg = Double(s.over) / Double(s.count)
                        Text(String(format: "%+.2f", avg))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(avg <= 0 ? Brand.live : Brand.text)
                        Text("(\(s.count))").font(.caption).foregroundStyle(Brand.text3)
                    } else {
                        Text("—").foregroundStyle(Brand.text3)
                    }
                }
                .font(.subheadline)
            }
        }
        .glassCard()
    }
}
