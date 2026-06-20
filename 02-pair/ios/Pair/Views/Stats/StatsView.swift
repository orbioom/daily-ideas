import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \PairResult.date, order: .reverse) private var results: [PairResult]

    private var totalGames: Int { results.count }

    private func bestMoves(for size: GridSize) -> Int? {
        results.filter { $0.gridSize == size.rawValue }.map(\.moves).min()
    }

    private var favoriteTheme: String {
        let counts = Dictionary(grouping: results, by: { $0.theme })
            .mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })
            .flatMap { CardTheme(rawValue: $0.key)?.displayName }
            ?? "None yet"
    }

    private var last14Days: [(day: Date, count: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<14).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let count = results.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            return (day: day, count: count)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PairTheme.background.ignoresSafeArea()

                if results.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar.xaxis",
                        title: "No Stats Yet",
                        message: "Play some games to see your statistics here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            overviewCards
                            bestMovesSection
                            chartSection
                            favoriteSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var overviewCards: some View {
        HStack(spacing: 12) {
            statCard(value: "\(totalGames)", label: "Total Games", icon: "gamecontroller.fill")
            statCard(
                value: results.isEmpty ? "—" : formatDuration(results.map(\.durationSeconds).reduce(0, +) / Double(results.count)),
                label: "Avg. Time",
                icon: "clock.fill"
            )
        }
    }

    private var bestMovesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Moves")
                .font(.headline)
                .foregroundStyle(PairTheme.textSecondary)

            HStack(spacing: 10) {
                ForEach(GridSize.allCases, id: \.rawValue) { size in
                    VStack(spacing: 6) {
                        Text(size.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(PairTheme.textSecondary)
                        Text(bestMoves(for: size).map { "\($0)" } ?? "—")
                            .font(.title3.bold())
                            .foregroundStyle(PairTheme.accent)
                        Text("moves")
                            .font(.caption2)
                            .foregroundStyle(PairTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PairTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Games per Day (14 days)")
                .font(.headline)
                .foregroundStyle(PairTheme.textSecondary)

            Chart {
                ForEach(last14Days, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day, unit: .day),
                        y: .value("Games", item.count)
                    )
                    .foregroundStyle(PairTheme.accent)
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                        .foregroundStyle(PairTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(PairTheme.textSecondary)
                    AxisGridLine()
                        .foregroundStyle(PairTheme.surface)
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(PairTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var favoriteSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Favorite Theme")
                    .font(.subheadline)
                    .foregroundStyle(PairTheme.textSecondary)
                Text(favoriteTheme)
                    .font(.title3.bold())
                    .foregroundStyle(PairTheme.textPrimary)
            }
            Spacer()
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundStyle(PairTheme.accent)
        }
        .padding(20)
        .background(PairTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(PairTheme.accent)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(PairTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(PairTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(PairTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = Int(seconds)
        let m = s / 60
        return String(format: "%d:%02d", m, s % 60)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [PairResult.self, PairSettings.self], inMemory: true)
}
