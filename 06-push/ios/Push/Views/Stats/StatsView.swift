import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var records: [PushRecord]
    @Query private var dailyResults: [PushDailyResult]

    private var totalSolved: Int { records.count }
    private var totalLevels: Int { allLevels.count }

    private var perPackData: [(pack: LevelPack, solved: Int)] {
        allPacks.filter { $0.id != 5 }.map { pack in
            let solved = records.filter { $0.packId == pack.id }.count
            return (pack, solved)
        }
    }

    private var streak: Int {
        let solvedDates = dailyResults.filter { $0.solved }.map { $0.dateString }.sorted(by: >)
        var count = 0
        var checkDate = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        for _ in 0..<365 {
            let ds = fmt.string(from: checkDate)
            if solvedDates.contains(ds) {
                count += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if records.isEmpty && dailyResults.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        // Summary cards
                        summaryRow

                        // Chart
                        chartSection

                        // Per-pack breakdown
                        packBreakdown

                        // Daily stats
                        dailySection
                    }
                    .padding(16)
                }
            }
            .background(PushTheme.background.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.bar")
                .font(.system(size: 56))
                .foregroundColor(PushTheme.wall.opacity(0.2))
            Text("Solve your first puzzle\nto see stats!")
                .font(.system(.title3, design: .rounded, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(PushTheme.wall.opacity(0.4))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: 12) {
            summaryCard(
                icon: "checkmark.seal.fill",
                value: "\(totalSolved)",
                label: "Solved",
                color: PushTheme.boxOnTarget
            )
            summaryCard(
                icon: "flame.fill",
                value: "\(streak)",
                label: "Day Streak",
                color: .orange
            )
            summaryCard(
                icon: "square.grid.2x2.fill",
                value: "\(totalLevels - totalSolved)",
                label: "Remaining",
                color: PushTheme.accent
            )
        }
    }

    private func summaryCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundColor(PushTheme.wall)
                .monospacedDigit()
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress by Pack")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(PushTheme.wall.opacity(0.6))
                .padding(.horizontal, 4)

            Chart {
                ForEach(perPackData, id: \.pack.id) { item in
                    BarMark(
                        x: .value("Pack", item.pack.name),
                        y: .value("Solved", item.solved)
                    )
                    .foregroundStyle(PushTheme.packColor(item.pack.id))
                    .cornerRadius(6)
                    .annotation(position: .top, alignment: .center) {
                        if item.solved > 0 {
                            Text("\(item.solved)")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundColor(PushTheme.wall.opacity(0.6))
                        }
                    }
                }
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(values: [0, 5, 10]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(PushTheme.wall.opacity(0.1))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(PushTheme.wall.opacity(0.4))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(s)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(PushTheme.wall.opacity(0.6))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }

    // MARK: - Pack Breakdown

    private var packBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pack Completion")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(PushTheme.wall.opacity(0.6))
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(allPacks.filter { $0.id != 5 }) { pack in
                    let solved = records.filter { $0.packId == pack.id }.count
                    let total = pack.levelCount
                    let pct = total > 0 ? Double(solved) / Double(total) : 0

                    VStack(spacing: 5) {
                        HStack {
                            Circle()
                                .fill(PushTheme.packColor(pack.id))
                                .frame(width: 10, height: 10)
                            Text(pack.name)
                                .font(.system(.callout, design: .rounded, weight: .medium))
                                .foregroundColor(PushTheme.wall)
                            Spacer()
                            Text("\(solved)/\(total)")
                                .font(.system(.callout, design: .rounded, weight: .semibold))
                                .foregroundColor(PushTheme.packColor(pack.id))
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(PushTheme.floor).frame(height: 6)
                                Capsule()
                                    .fill(PushTheme.packColor(pack.id))
                                    .frame(width: geo.size.width * pct, height: 6)
                                    .animation(.spring(duration: 0.6), value: solved)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }

    // MARK: - Daily Section

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Puzzles")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(PushTheme.wall.opacity(0.6))
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                let totalDaily = dailyResults.count
                let solvedDaily = dailyResults.filter { $0.solved }.count

                summaryCard(
                    icon: "calendar.badge.checkmark",
                    value: "\(solvedDaily)",
                    label: "Daily Wins",
                    color: PushTheme.pack5
                )
                summaryCard(
                    icon: "calendar",
                    value: "\(totalDaily)",
                    label: "Attempted",
                    color: PushTheme.wall.opacity(0.4)
                )
            }
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [PushRecord.self, PushPrefs.self, PushDailyResult.self, PushOnboarding.self], inMemory: true)
}
