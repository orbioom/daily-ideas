import SwiftUI
import SwiftData
import Charts

struct ArchiveView: View {
    @Query private var allProgress: [PuzzleProgress]

    private var solved: [PuzzleProgress] { allProgress.filter { $0.solved } }
    private var solvedIds: Set<Int> { Set(solved.map { $0.puzzleId }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsCard
                    timeChart
                    sizeBreakdown
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Archive")
        }
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statCell(value: "\(solved.count)", label: "Solved")
            Divider().frame(height: 44)
            statCell(value: "\(PixPuzzleBank.puzzles5x5.filter { solvedIds.contains($0.id) }.count)/\(PixPuzzleBank.puzzles5x5.count)", label: "5×5")
            Divider().frame(height: 44)
            statCell(value: "\(PixPuzzleBank.puzzles10x10.filter { solvedIds.contains($0.id) }.count)/\(PixPuzzleBank.puzzles10x10.count)", label: "10×10")
            Divider().frame(height: 44)
            statCell(value: bestTimeFormatted, label: "Best")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var bestTimeFormatted: String {
        guard let best = solved.min(by: { $0.elapsedSeconds < $1.elapsedSeconds }) else { return "--" }
        let t = Int(best.elapsedSeconds)
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    private var timeChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Solve Times")
                .font(.system(size: 15, weight: .bold, design: .rounded))

            if solved.isEmpty {
                Text("Solve puzzles to see your times here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                Chart(solved.sorted { $0.elapsedSeconds < $1.elapsedSeconds }.prefix(20)) { prog in
                    let puzzle = PixPuzzleBank.all.first { $0.id == prog.puzzleId }
                    BarMark(
                        x: .value("Puzzle", puzzle?.name ?? "#\(prog.puzzleId)"),
                        y: .value("Seconds", prog.elapsedSeconds)
                    )
                    .foregroundStyle(PixTheme.accent.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks { val in
                        AxisValueLabel {
                            if let s = val.as(Double.self) {
                                Text(formatSeconds(s)).font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 140)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var sizeBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progress by Size")
                .font(.system(size: 15, weight: .bold, design: .rounded))

            progressRow(label: "5×5 Puzzles",
                        done: PixPuzzleBank.puzzles5x5.filter { solvedIds.contains($0.id) }.count,
                        total: PixPuzzleBank.puzzles5x5.count)
            progressRow(label: "10×10 Puzzles",
                        done: PixPuzzleBank.puzzles10x10.filter { solvedIds.contains($0.id) }.count,
                        total: PixPuzzleBank.puzzles10x10.count)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func progressRow(label: String, done: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text("\(done)/\(total)").font(.subheadline.bold()).foregroundStyle(PixTheme.accent)
            }
            ProgressView(value: Double(done), total: Double(total))
                .tint(PixTheme.accent)
        }
        .padding(.vertical, 4)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(PixTheme.accent)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatSeconds(_ s: Double) -> String {
        let t = Int(s)
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
