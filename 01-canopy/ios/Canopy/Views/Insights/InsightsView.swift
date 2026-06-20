import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \EmissionEntry.date, order: .reverse) private var allEntries: [EmissionEntry]
    @Query private var settings: [CanopySettings]

    private var currentSettings: CanopySettings? { settings.first }
    private var weeklyGoal: Double { currentSettings?.weeklyGoalKg ?? 92.0 }

    private var weeklyData: [(weekStart: Date, kg: Double)] {
        InsightsEngine.last8WeeksTotals(entries: allEntries)
    }

    private var categoryData: [(EmissionCategory, Double)] {
        let calendar = Calendar.current
        guard let eightWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -8, to: Date()) else {
            return []
        }
        return InsightsEngine.categoryBreakdown(entries: allEntries, in: eightWeeksAgo...Date())
    }

    private var totalLogged: Double { InsightsEngine.totalLogged(entries: allEntries) }
    private var streak: Int { InsightsEngine.currentStreakDaysUnder(goalKg: weeklyGoal, entries: allEntries) }
    private var bestWeek: Double { InsightsEngine.bestWeekKg(entries: allEntries) }
    private var co2eSaved: Double { InsightsEngine.co2eSavedVsWorldAvg(entries: allEntries) }

    private var hasData: Bool { !allEntries.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if hasData {
                    ScrollView {
                        VStack(spacing: CanopyTheme.sectionSpacing) {
                            barChartSection
                            donutChartSection
                            benchmarkSection
                            statsGridSection
                        }
                        .padding(.vertical)
                    }
                } else {
                    EmptyStateView(
                        systemImage: "chart.bar.fill",
                        title: "No data yet",
                        subtitle: "Log a few emissions to unlock insights and trend charts."
                    )
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Bar Chart

    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("8-Week Trend", icon: "chart.bar.fill")

            Chart {
                ForEach(weeklyData, id: \.weekStart) { dataPoint in
                    BarMark(
                        x: .value("Week", dataPoint.weekStart, unit: .weekOfYear),
                        y: .value("kg CO₂e", dataPoint.kg)
                    )
                    .foregroundStyle(
                        dataPoint.kg > weeklyGoal ? Color(hex: "E63946") : Color.canopyLight
                    )
                    .cornerRadius(6)
                }

                RuleMark(y: .value("Goal", weeklyGoal))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(.canopyGreen)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundStyle(.canopyGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.canopyGreen.opacity(0.1), in: Capsule())
                    }

                RuleMark(y: .value("World Avg", EmissionsEngine.worldAverageWeeklyKg))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let kg = value.as(Double.self) {
                            Text("\(Int(kg))kg")
                                .font(.caption2)
                        }
                    }
                }
            }
            .accessibilityLabel("8-week bar chart showing your weekly CO2e emissions")
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
        .padding(.horizontal)
    }

    // MARK: - Donut Chart

    private var donutChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("By Category (8 weeks)", icon: "chart.pie.fill")

            if categoryData.isEmpty {
                Text("No category data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                HStack(alignment: .center, spacing: 20) {
                    Chart(categoryData, id: \.0) { item in
                        SectorMark(
                            angle: .value("kg", item.1),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(item.0.swiftUIColor)
                        .cornerRadius(4)
                    }
                    .frame(width: 160, height: 160)
                    .accessibilityLabel("Donut chart showing emission breakdown by category")

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categoryData, id: \.0) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.0.swiftUIColor)
                                    .frame(width: 10, height: 10)
                                Text(item.0.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(String(format: "%.0f kg", item.1))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
        .padding(.horizontal)
    }

    // MARK: - Benchmarks

    private var benchmarkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("vs Benchmarks", icon: "globe")

            let userAvgWeekly: Double = {
                let nonZero = weeklyData.filter { $0.kg > 0 }
                guard !nonZero.isEmpty else { return 0 }
                return nonZero.map(\.kg).reduce(0, +) / Double(nonZero.count)
            }()

            VStack(spacing: 10) {
                benchmarkRow(
                    label: "Your weekly avg",
                    value: userAvgWeekly,
                    color: userAvgWeekly < weeklyGoal ? .canopyLight : Color(hex: "E63946"),
                    maxValue: EmissionsEngine.worldAverageWeeklyKg
                )

                benchmarkRow(
                    label: "Your goal",
                    value: weeklyGoal,
                    color: .canopyGreen,
                    maxValue: EmissionsEngine.worldAverageWeeklyKg
                )

                benchmarkRow(
                    label: "Paris target",
                    value: EmissionsEngine.targetWeeklyKg,
                    color: Color(hex: "4A90D9"),
                    maxValue: EmissionsEngine.worldAverageWeeklyKg
                )

                benchmarkRow(
                    label: "World average",
                    value: EmissionsEngine.worldAverageWeeklyKg,
                    color: Color(hex: "E63946").opacity(0.7),
                    maxValue: EmissionsEngine.worldAverageWeeklyKg
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
        .padding(.horizontal)
    }

    private func benchmarkRow(label: String, value: Double, color: Color, maxValue: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(String(format: "%.1f kg/wk", value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(color.opacity(0.85))
                        .frame(width: geo.size.width * min(value / maxValue, 1.0))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(String(format: "%.1f", value)) kilograms per week")
    }

    // MARK: - Stats Grid

    private var statsGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Your Impact", icon: "leaf.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statTile(
                    label: "Total Logged",
                    value: String(format: "%.0f kg", totalLogged),
                    icon: "sum",
                    color: .canopyGreen
                )
                statTile(
                    label: "Best Week",
                    value: bestWeek > 0 ? String(format: "%.1f kg", bestWeek) : "—",
                    icon: "star.fill",
                    color: Color(hex: "F5C518")
                )
                statTile(
                    label: "Current Streak",
                    value: streak > 0 ? "\(streak) day\(streak == 1 ? "" : "s")" : "0 days",
                    icon: "flame.fill",
                    color: Color(hex: "E8821A")
                )
                statTile(
                    label: "Saved vs World",
                    value: String(format: "%.0f kg", co2eSaved),
                    icon: "globe.americas.fill",
                    color: Color(hex: "4A90D9")
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
        .padding(.horizontal)
    }

    private func statTile(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.smallCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [EmissionEntry.self, CanopySettings.self], inMemory: true)
}
