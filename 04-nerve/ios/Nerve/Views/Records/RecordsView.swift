import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]

    private var solvedRecords: [GameRecord] { records.filter(\.isSolved) }

    private var avgGuesses: Double {
        guard !solvedRecords.isEmpty else { return 0 }
        return Double(solvedRecords.map(\.guessCount).reduce(0, +)) / Double(solvedRecords.count)
    }

    private var avgTime: Double {
        guard !solvedRecords.isEmpty else { return 0 }
        return Double(solvedRecords.map(\.elapsedSeconds).reduce(0, +)) / Double(solvedRecords.count)
    }

    private var winRate: Double {
        guard !records.isEmpty else { return 0 }
        return Double(solvedRecords.count) / Double(records.count) * 100
    }

    private var guessDist: [Int: Int] {
        var dist: [Int: Int] = [:]
        for r in solvedRecords { dist[r.guessCount, default: 0] += 1 }
        return dist
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()

            if records.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Your Records")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        statsGrid

                        if !solvedRecords.isEmpty {
                            guessDistributionChart
                        }

                        recentGames
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundStyle(.purple.opacity(0.6))
            Text("No Records Yet")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text("Play some games to see your stats here.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(value: "\(records.count)", label: "Played", color: .purple)
            statCard(value: String(format: "%.0f%%", winRate), label: "Win Rate", color: .green)
            statCard(value: String(format: "%.1f", avgGuesses), label: "Avg Guesses", color: .orange)
            statCard(value: solvedRecords.count.description, label: "Solved", color: .cyan)
            statCard(value: timeStr(Int(avgTime)), label: "Avg Time", color: .pink)
            let best = solvedRecords.map(\.guessCount).min() ?? 0
            statCard(value: solvedRecords.isEmpty ? "—" : "\(best)", label: "Best", color: .yellow)
        }
        .padding(.horizontal, 20)
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var guessDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guess Distribution")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))

            let maxVal = guessDist.values.max() ?? 1
            VStack(spacing: 8) {
                ForEach(1...NerveEngine.maxGuesses, id: \.self) { g in
                    let count = guessDist[g] ?? 0
                    HStack(spacing: 8) {
                        Text("\(g)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 18, alignment: .trailing)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(count > 0 ? Color.purple : Color.white.opacity(0.08))
                                .frame(width: count > 0 ? max(30, geo.size.width * CGFloat(count) / CGFloat(maxVal)) : 6)
                        }
                        .frame(height: 20)
                        Text(count > 0 ? "\(count)" : "")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 24, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 20)

            ForEach(records.prefix(10)) { r in
                HStack {
                    Image(systemName: r.isSolved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(r.isSolved ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.difficulty)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        Text(r.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    Spacer()
                    if r.isSolved {
                        Text("\(r.guessCount) guesses")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Text(timeStr(r.elapsedSeconds))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
            }
        }
    }

    private func timeStr(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }
}
