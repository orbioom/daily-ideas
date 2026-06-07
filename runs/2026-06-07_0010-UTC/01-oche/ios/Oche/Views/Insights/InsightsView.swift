import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Match.date) private var matches: [Match]

    private var allLegs: [Leg] { matches.flatMap(\.legs) }

    private var careerAverage: Double {
        let darts = allLegs.reduce(0) { $0 + $1.dartsThrown }
        guard darts > 0 else { return 0 }
        let points = allLegs.reduce(0) { $0 + $1.pointsScored }
        return Double(points) / Double(darts) * 3.0
    }

    private var winRate: Double {
        guard !matches.isEmpty else { return 0 }
        return Double(matches.filter(\.didWin).count) / Double(matches.count) * 100
    }

    private var checkoutPercent: Double {
        let attempts = allLegs.reduce(0) { $0 + $1.doubleAttempts }
        guard attempts > 0 else { return 0 }
        let hits = allLegs.filter { $0.didWin && $0.checkoutDouble > 0 }.count
        return Double(hits) / Double(attempts) * 100
    }

    private var bestLeg: Int? { allLegs.filter(\.didWin).map(\.dartsThrown).min() }
    private var maxVisit: Int { allLegs.map(\.highestScore).max() ?? 0 }

    /// Recent matches with a computed average, oldest→newest, last 10.
    private struct Point: Identifiable {
        let id = UUID(); let label: String; let avg: Double; let won: Bool
    }
    private var trend: [Point] {
        matches.suffix(10).enumerated().map { i, m in
            Point(label: "\(i + 1)", avg: m.threeDartAverage, won: m.didWin)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    if matches.isEmpty {
                        EmptyStateView(icon: "chart.bar.xaxis",
                                       title: "No insights yet",
                                       message: "Log a few matches and Oche charts your scoring average, checkout %, and form over time.")
                            .padding(.top, 50)
                    } else {
                        VStack(spacing: 18) {
                            statGrid
                            trendCard
                            recordsCard
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: Fmt.avg(careerAverage), label: "Career avg", accent: Brand.text)
                StatTile(value: Fmt.pct(winRate), label: "Win rate", accent: Brand.live)
            }
            HStack(spacing: 12) {
                StatTile(value: Fmt.pct(checkoutPercent), label: "Checkout %", accent: Brand.live)
                StatTile(value: bestLeg.map { "\($0)" } ?? "—", label: "Best leg")
            }
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Average by match", trailing: "last \(trend.count)")
            Chart(trend) { p in
                BarMark(
                    x: .value("Match", p.label),
                    y: .value("Average", p.avg)
                )
                .foregroundStyle(p.won ? Brand.live : Brand.text2)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...max(60, (trend.map(\.avg).max() ?? 60) + 10))
            .frame(height: 180)
            .accessibilityLabel("Three-dart average across your last \(trend.count) matches")
        }
        .glassCard()
    }

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Records")
            VStack(spacing: 10) {
                recordRow("Highest visit", "\(maxVisit)", Brand.magic)
                recordRow("Matches played", "\(matches.count)", Brand.text)
                recordRow("Legs won", "\(allLegs.filter(\.didWin).count)", Brand.live)
                recordRow("Total darts thrown", "\(allLegs.reduce(0) { $0 + $1.dartsThrown })", Brand.text2)
            }
            .glassCard()
        }
    }

    private func recordRow(_ label: String, _ value: String, _ tint: Color) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(Brand.mono(16, weight: .semibold)).foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
