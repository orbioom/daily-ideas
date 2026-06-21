import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \SlideRecord.date, order: .reverse) private var records: [SlideRecord]
    @Query private var dailyResults: [SlideDailyResult]

    var bestBySize: [Int: (moves: Int, time: Double)] {
        var bests: [Int: (moves: Int, time: Double)] = [:]
        for rec in records {
            let cur = bests[rec.size]
            if cur == nil || rec.moves < cur!.moves {
                bests[rec.size] = (rec.moves, rec.seconds)
            }
        }
        return bests
    }

    var chartData: [(size: String, count: Int)] {
        [3, 4, 5].map { s in
            let count = records.filter { $0.size == s }.count
            return (size: "\(s)x\(s)", count: count)
        }
    }

    var dailySolvedCount: Int {
        dailyResults.filter { $0.solved }.count
    }

    var currentStreak: Int {
        var streak = 0
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        var date = Date()
        while true {
            let str = fmt.string(from: date)
            guard dailyResults.contains(where: { $0.dateString == str && $0.solved }) else { break }
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return streak
    }

    var body: some View {
        ZStack {
            SlideTheme.background.ignoresSafeArea()
            if records.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundStyle(SlideTheme.textSecondary)
                    Text("No games yet")
                        .font(.title2)
                        .foregroundStyle(.white)
                    Text("Play some puzzles to see your stats!")
                        .foregroundStyle(SlideTheme.textSecondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Best per size
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best Scores")
                                .font(.headline)
                                .foregroundStyle(.white)
                            ForEach([3, 4, 5], id: \.self) { s in
                                HStack {
                                    Text("\(s)×\(s)")
                                        .foregroundStyle(SlideTheme.textSecondary)
                                    Spacer()
                                    if let best = bestBySize[s] {
                                        VStack(alignment: .trailing) {
                                            Text("\(best.moves) moves")
                                                .foregroundStyle(SlideTheme.accent)
                                            Text(String(format: "%.0fs", best.time))
                                                .font(.caption)
                                                .foregroundStyle(SlideTheme.textSecondary)
                                        }
                                    } else {
                                        Text("Not played")
                                            .foregroundStyle(SlideTheme.textSecondary)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(SlideTheme.tileBg, in: .rect(cornerRadius: 10))
                            }
                        }

                        // Chart — games played by size
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Games Played by Size")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Chart(chartData, id: \.size) { item in
                                BarMark(
                                    x: .value("Size", item.size),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(SlideTheme.accent)
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks(values: .automatic) { _ in
                                    AxisGridLine().foregroundStyle(SlideTheme.border)
                                    AxisValueLabel().foregroundStyle(SlideTheme.textSecondary)
                                }
                            }
                        }
                        .padding()
                        .background(SlideTheme.tileBg, in: .rect(cornerRadius: 16))

                        // Summary stats
                        VStack(spacing: 8) {
                            HStack {
                                Text("Total Puzzles Solved")
                                    .foregroundStyle(SlideTheme.textSecondary)
                                Spacer()
                                Text("\(records.count)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            .background(SlideTheme.tileBg, in: .rect(cornerRadius: 12))

                            HStack {
                                Text("Daily Challenges Completed")
                                    .foregroundStyle(SlideTheme.textSecondary)
                                Spacer()
                                Text("\(dailySolvedCount)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            .background(SlideTheme.tileBg, in: .rect(cornerRadius: 12))

                            HStack {
                                Label("Current Daily Streak", systemImage: "flame.fill")
                                    .foregroundStyle(SlideTheme.textSecondary)
                                Spacer()
                                Text("\(currentStreak) day\(currentStreak == 1 ? "" : "s")")
                                    .font(.headline)
                                    .foregroundStyle(currentStreak > 0 ? SlideTheme.accent : .white)
                            }
                            .padding()
                            .background(SlideTheme.tileBg, in: .rect(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Stats")
    }
}
