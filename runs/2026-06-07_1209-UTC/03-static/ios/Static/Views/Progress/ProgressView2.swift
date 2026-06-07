import SwiftUI
import SwiftData
import Charts

/// Progress dashboard. Named `ProgressView2` to avoid clashing with SwiftUI's
/// built-in `ProgressView`.
struct ProgressView2: View {
    @Query(sort: \ApneaSession.date) private var sessions: [ApneaSession]

    private var pbPoints: [PBPoint] {
        var best = 0
        return sessions.map { s in
            best = max(best, s.longestHoldSeconds)
            return PBPoint(date: s.date, hold: s.longestHoldSeconds, runningBest: best)
        }
    }
    private var personalBest: Int { sessions.map { $0.longestHoldSeconds }.max() ?? 0 }
    private var totalRounds: Int { sessions.map { $0.roundsCompleted }.reduce(0, +) }
    private var co2Count: Int { sessions.filter { $0.type == .co2 }.count }
    private var o2Count: Int { sessions.filter { $0.type == .o2 }.count }
    private var firstPB: Int { sessions.first?.longestHoldSeconds ?? 0 }
    private var improvement: Int { personalBest - firstPB }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.count < 2 {
                    ScrollView {
                        EmptyStateView(icon: "chart.xyaxis.line",
                                       title: "Not enough data yet",
                                       message: "Log a couple of sessions and your personal-best trend and training mix will appear here.")
                            .padding(.top, 50)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: TableEngine.clock(personalBest), label: "Best hold", accent: Brand.magic)
                                StatTile(value: "+\(TableEngine.clock(max(0, improvement)))", label: "Gained", accent: Brand.live)
                                StatTile(value: "\(sessions.count)", label: "Sessions")
                            }
                            pbChart
                            mixCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Progress")
            .background(Brand.pageBackground)
        }
    }

    private var pbChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Personal-best hold over time")
            Chart(pbPoints) { p in
                LineMark(x: .value("Date", p.date), y: .value("Best", p.runningBest))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Brand.text)
                PointMark(x: .value("Date", p.date), y: .value("Hold", p.hold))
                    .foregroundStyle(Brand.live)
                    .symbolSize(40)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Brand.hairline)
                    AxisValueLabel {
                        if let v = value.as(Int.self) { Text(TableEngine.clock(v)) }
                    }
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 200)
            .accessibilityLabel("Personal best hold trend over \(pbPoints.count) sessions")
        }.glassCard()
    }

    private var mixCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Training mix")
            let total = max(1, co2Count + o2Count)
            VStack(spacing: 10) {
                mixRow("CO₂ tolerance", count: co2Count, total: total, color: Brand.warn, icon: "wind")
                mixRow("O₂ efficiency", count: o2Count, total: total, color: Brand.info, icon: "lungs")
            }
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Total rounds trained", value: "\(totalRounds)", mono: true)
        }.glassCard()
    }

    private func mixRow(_ label: String, count: Int, total: Int, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(label, systemImage: icon).font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                Text("\(count)").font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
            }
            MeterBar(fraction: Double(count) / Double(total), color: color)
        }
    }
}

private struct PBPoint: Identifiable {
    let id = UUID()
    let date: Date
    let hold: Int
    let runningBest: Int
}
