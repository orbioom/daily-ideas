import SwiftUI
import SwiftData
import Charts

struct BrickRecordsView: View {
    @Query(sort: \BrickHighScore.level) private var scores: [BrickHighScore]

    private var totalScore: Int { scores.reduce(0) { $0 + $1.score } }
    private var levelsPlayed: Int { scores.filter { $0.score > 0 }.count }
    private var bestScore: Int { scores.map(\.score).max() ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        statCards
                        if !scores.isEmpty {
                            chartSection
                            scoresSection
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Records")
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.12), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var statCards: some View {
        HStack(spacing: 12) {
            StatCard(label: "BEST SCORE", value: "\(bestScore)", icon: "crown.fill", color: .yellow)
            StatCard(label: "LEVELS", value: "\(levelsPlayed)/\(BrickLayout.levels.count)", icon: "square.grid.2x2.fill", color: .orange)
            StatCard(label: "TOTAL", value: "\(totalScore)", icon: "sum", color: .blue)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Score by Level")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.7))

            Chart {
                ForEach(scores) { score in
                    BarMark(
                        x: .value("Level", "L\(score.level)"),
                        y: .value("Score", score.score)
                    )
                    .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.1))
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks(preset: .automatic) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .frame(height: 160)
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Level Bests")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.7))
            ForEach(scores) { score in
                HStack {
                    Text("Level \(score.level)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Label("\(score.score)", systemImage: "trophy.fill")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.yellow)
                    Text(score.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "trophy")
                .font(.system(size: 52))
                .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.1).opacity(0.5))
            Text("No records yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Text("Complete levels to set high scores")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.top, 60)
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
