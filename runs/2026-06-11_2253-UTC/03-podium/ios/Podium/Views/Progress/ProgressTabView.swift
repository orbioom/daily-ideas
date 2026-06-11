import SwiftUI
import SwiftData
import Charts

struct ProgressTabView: View {
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \SpeechSession.date) private var sessions: [SpeechSession]
    @AppStorage("targetWPMLow") private var targetLow = 120.0
    @AppStorage("targetWPMHigh") private var targetHigh = 160.0

    private var recent: [SpeechSession] { Array(sessions.suffix(20)) }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.count < 2 {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "Progress needs practice",
                                   message: "Save at least two sessions and Podium will chart your score, filler rate, and pace over time.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statRow
                            scoreChart
                            fillerChart
                            paceChart
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Progress")
        }
    }

    private var statRow: some View {
        let totalMinutes = sessions.reduce(0.0) { $0 + $1.duration } / 60
        let avgScore = sessions.isEmpty ? 0 : sessions.reduce(0) { $0 + $1.score } / sessions.count
        let best = sessions.map(\.score).max() ?? 0
        return HStack(spacing: 12) {
            statTile(title: "Takes", value: "\(sessions.count)")
            statTile(title: "Stage time", value: String(format: "%.0f min", totalMinutes))
            statTile(title: "Avg score", value: "\(avgScore)")
            statTile(title: "Best", value: "\(best)")
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft(scheme))
            Text(value)
                .font(Theme.display(18))
                .foregroundStyle(Theme.ink(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var scoreChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delivery score").font(.headline)
            Chart(Array(recent.enumerated()), id: \.element.persistentModelID) { item in
                LineMark(x: .value("Take", item.offset),
                         y: .value("Score", item.element.score))
                .foregroundStyle(Theme.violet)
                .interpolationMethod(.monotone)
                PointMark(x: .value("Take", item.offset),
                          y: .value("Score", item.element.score))
                .foregroundStyle(Theme.scoreColor(item.element.score))
            }
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .frame(height: 170)
            .accessibilityLabel("Line chart of delivery score across your last \(recent.count) takes")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .podiumCard()
    }

    private var fillerChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fillers per minute").font(.headline)
            Text("Under 2/min sounds polished.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft(scheme))
            Chart(Array(recent.enumerated()), id: \.element.persistentModelID) { item in
                BarMark(x: .value("Take", item.offset),
                        y: .value("Fillers/min", item.element.fillersPerMinute))
                .foregroundStyle(item.element.fillersPerMinute <= 2 ? Theme.green : Theme.gold)
                .cornerRadius(3)
                RuleMark(y: .value("Target", 2))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
            .chartXAxis(.hidden)
            .frame(height: 150)
            .accessibilityLabel("Bar chart of filler words per minute per take, target line at 2")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .podiumCard()
    }

    private var paceChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Speaking pace").font(.headline)
            Text("Shaded band is your target: \(Int(targetLow))–\(Int(targetHigh)) wpm.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft(scheme))
            Chart {
                RectangleMark(xStart: .value("Start", -0.5),
                              xEnd: .value("End", Double(max(recent.count, 1)) - 0.5),
                              yStart: .value("Low", targetLow),
                              yEnd: .value("High", targetHigh))
                .foregroundStyle(Theme.green.opacity(0.12))
                ForEach(Array(recent.enumerated()), id: \.element.persistentModelID) { item in
                    LineMark(x: .value("Take", Double(item.offset)),
                             y: .value("WPM", item.element.wordsPerMinute))
                    .foregroundStyle(Theme.violet)
                    .interpolationMethod(.monotone)
                    PointMark(x: .value("Take", Double(item.offset)),
                              y: .value("WPM", item.element.wordsPerMinute))
                    .foregroundStyle(Theme.violet)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 170)
            .accessibilityLabel("Line chart of words per minute per take with your target band shaded")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .podiumCard()
    }
}
