import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Round.date) private var allRounds: [Round]
    @AppStorage("chains.ratingWindow") private var ratingWindow = 8

    private var rounds: [Round] { allRounds.filter { $0.isComplete && $0.holesPlayed > 0 } }

    private var ratingPoints: [RatingPoint] {
        rounds.map { r in
            RatingPoint(date: r.date,
                        rating: RatingEngine.rating(strokes: r.totalStrokes, ssa: r.ssa, pointsPerThrow: r.pointsPerThrow))
        }
    }

    private var averageRating: Int {
        let recent = ratingPoints.suffix(ratingWindow).map { $0.rating }
        guard !recent.isEmpty else { return 0 }
        return recent.reduce(0, +) / recent.count
    }

    private var bestRating: Int { ratingPoints.map { $0.rating }.max() ?? 0 }

    private var avgToPar: Double {
        guard !rounds.isEmpty else { return 0 }
        return Double(rounds.map { $0.relativeToPar }.reduce(0, +)) / Double(rounds.count)
    }

    /// Per-hole average relative-to-par for the most-played course.
    private var troubleHoles: (course: String, holes: [TroubleHole]) {
        let grouped = Dictionary(grouping: rounds, by: { $0.courseName })
        guard let (name, list) = grouped.max(by: { $0.value.count < $1.value.count }) else {
            return ("", [])
        }
        var sum: [Int: Int] = [:]; var count: [Int: Int] = [:]
        for r in list {
            for s in r.scores {
                sum[s.holeNumber, default: 0] += s.relative
                count[s.holeNumber, default: 0] += 1
            }
        }
        let holes = sum.keys.sorted().compactMap { n -> TroubleHole? in
            guard let c = count[n], c > 0 else { return nil }
            return TroubleHole(number: n, avgRelative: Double(sum[n] ?? 0) / Double(c))
        }
        return (name, holes.sorted { $0.avgRelative > $1.avgRelative })
    }

    var body: some View {
        NavigationStack {
            Group {
                if rounds.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "chart.xyaxis.line",
                                       title: "No stats yet",
                                       message: "Finish a round or two and your rating trend, scoring average, and trouble holes will show up here.")
                            .padding(.top, 50)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(averageRating)", label: "Avg rating", accent: Brand.text)
                                StatTile(value: "\(bestRating)", label: "Best", accent: Brand.live)
                                StatTile(value: Fmt.relative(Int(avgToPar.rounded())), label: "Avg to par")
                            }

                            ratingChart
                            troubleHolesCard
                            distributionCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Stats")
            .background(Brand.pageBackground)
        }
    }

    private var ratingChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Rating trend")
            Chart(ratingPoints) { p in
                LineMark(x: .value("Date", p.date), y: .value("Rating", p.rating))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Brand.text)
                AreaMark(x: .value("Date", p.date), y: .value("Rating", p.rating))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [Brand.live.opacity(0.30), .clear],
                                                    startPoint: .top, endPoint: .bottom))
                PointMark(x: .value("Date", p.date), y: .value("Rating", p.rating))
                    .foregroundStyle(Brand.live)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 180)
            .accessibilityLabel("Rating trend over \(ratingPoints.count) rounds")
        }.glassCard()
    }

    private var troubleHolesCard: some View {
        let data = troubleHoles
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: data.course.isEmpty ? "Trouble holes" : "Trouble holes · \(data.course)")
            if data.holes.isEmpty {
                Text("Play a course more than once to see which holes cost you strokes.")
                    .font(.caption).foregroundStyle(Brand.text2)
            } else {
                Chart(data.holes) { h in
                    BarMark(x: .value("Hole", "\(h.number)"),
                            y: .value("Avg", h.avgRelative))
                        .foregroundStyle(h.avgRelative > 0 ? Brand.danger : Brand.live)
                        .cornerRadius(4)
                }
                .frame(height: 160)
                .accessibilityLabel("Average score relative to par per hole")
                if let worst = data.holes.first, worst.avgRelative > 0 {
                    Text("Hole \(worst.number) is your toughest — averaging \(String(format: "%+.1f", worst.avgRelative)) to par.")
                        .font(.caption).foregroundStyle(Brand.text2)
                }
            }
        }.glassCard()
    }

    private var distributionCard: some View {
        var counts: [ScoreKind: Int] = [:]
        for r in rounds { for k in ScoreKind.allCases { counts[k, default: 0] += r.tally(k) } }
        let total = max(1, counts.values.reduce(0, +))
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Scoring mix")
            ForEach(ScoreKind.allCases, id: \.self) { kind in
                let n = counts[kind] ?? 0
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(kind.rawValue).font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(n)").font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
                    }
                    MeterBar(fraction: Double(n) / Double(total),
                             color: kind == .par ? Brand.text3 : (kind == .birdie || kind == .eagle || kind == .ace ? Brand.live : Brand.warn))
                }
            }
        }.glassCard()
    }
}

private struct RatingPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Int
}

private struct TroubleHole: Identifiable {
    var id: Int { number }
    let number: Int
    let avgRelative: Double
}
