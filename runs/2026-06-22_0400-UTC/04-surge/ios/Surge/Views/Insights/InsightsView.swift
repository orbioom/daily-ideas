import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    let profile: RunnerProfile
    @Query(sort: \RunLog.date) private var runLogs: [RunLog]
    @Query(sort: \PlannedRun.weekNumber) private var plannedRuns: [PlannedRun]
    @Query private var settings: [SurgeSettings]

    private var unit: String { settings.first?.unit ?? "km" }

    private var recentLogs: [RunLog] {
        Array(runLogs.suffix(30))
    }

    private var weeklyMileageData: [WeeklyMileage] {
        let calendar = Calendar.current
        var data: [WeeklyMileage] = []
        for weekOffset in (0..<14).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date()),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            let weekLogs = runLogs.filter { $0.date >= weekStart && $0.date < weekEnd }
            let actualKm = weekLogs.reduce(0) { $0 + $1.distanceKm }
            let weekNumber = profile.currentWeekNumber - weekOffset
            let plannedKm = weekNumber > 0
                ? plannedRuns.filter { $0.weekNumber == weekNumber }.reduce(0) { $0 + $1.distanceKm }
                : 0
            let label = weekOffset == 0 ? "Now" : "W\(14 - weekOffset)"
            data.append(WeeklyMileage(
                label: label,
                actualKm: actualKm,
                plannedKm: plannedKm,
                weekOffset: weekOffset
            ))
        }
        return data
    }

    private var paceData: [PaceDataPoint] {
        recentLogs
            .filter { $0.paceSecondsPerKm > 0 && $0.type.isRunningWorkout }
            .enumerated()
            .map { index, log in
                PaceDataPoint(index: index, paceSeconds: log.paceSecondsPerKm, date: log.date, runType: log.type)
            }
    }

    private var longRunData: [LongRunPoint] {
        let calendar = Calendar.current
        var longestByWeek: [Int: Double] = [:]
        for log in runLogs where log.type == .long || log.distanceKm >= 15 {
            let weekOfYear = calendar.component(.weekOfYear, from: log.date)
            longestByWeek[weekOfYear] = max(longestByWeek[weekOfYear] ?? 0, log.distanceKm)
        }
        return longestByWeek.sorted { $0.key < $1.key }.enumerated().map { index, pair in
            LongRunPoint(index: index, distanceKm: pair.value)
        }
    }

    private var trainingLoadScore: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentWeekLogs = runLogs.filter { $0.date >= weekAgo }
        let weekKm = recentWeekLogs.reduce(0) { $0 + $1.distanceKm }
        let avgEffort = recentWeekLogs.isEmpty ? 0.0 : Double(recentWeekLogs.reduce(0) { $0 + $1.perceivedEffort }) / Double(recentWeekLogs.count)
        return Int(min(100, weekKm * avgEffort / 3.0))
    }

    private var goalPaceReadiness: Double {
        guard !paceData.isEmpty else { return 0 }
        let goalPace = PaceEngine.pace(finishTimeSeconds: profile.goalTimeSeconds, distanceKm: profile.raceType.distanceKm)
        let count = min(5, paceData.count)
        let recentAvgPace = paceData.suffix(count).reduce(0) { $0 + $1.paceSeconds } / Double(count)
        guard recentAvgPace > 0 else { return 0 }
        return min(1.0, max(0, (goalPace / recentAvgPace) * 0.8))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    quickStatsSection
                        .padding(.horizontal, 16)
                    weeklyMileageSection
                        .padding(.horizontal, 16)
                    if paceData.count >= 2 {
                        paceTrendSection
                            .padding(.horizontal, 16)
                    }
                    if longRunData.count >= 2 {
                        longRunProgressionSection
                            .padding(.horizontal, 16)
                    }
                    readinessSection
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                .padding(.bottom, 32)
            }
            .background(Color.surgeBackground.ignoresSafeArea())
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                InsightCard(
                    icon: "figure.run",
                    iconColor: .surgeAccent,
                    title: "Total Runs",
                    value: "\(runLogs.count)",
                    subtitle: "logged"
                )
                InsightCard(
                    icon: "map.fill",
                    iconColor: .surgeHighlight,
                    title: "Total Distance",
                    value: PaceEngine.formatDistance(runLogs.reduce(0) { $0 + $1.distanceKm }, unit: unit),
                    subtitle: "all time"
                )
            }
            HStack(spacing: 12) {
                InsightCard(
                    icon: "flame.fill",
                    iconColor: .surgeWarning,
                    title: "Training Load",
                    value: "\(trainingLoadScore)",
                    subtitle: "/ 100 this week"
                )
                InsightCard(
                    icon: "calendar.badge.checkmark",
                    iconColor: .surgeSuccess,
                    title: "Week",
                    value: "\(profile.currentWeekNumber) / \(profile.totalWeeks)",
                    subtitle: "of plan"
                )
            }
        }
    }

    // MARK: - Weekly Mileage

    private var weeklyMileageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Weekly Mileage", subtitle: "Last 14 weeks — gray = planned, color = actual")

            if weeklyMileageData.allSatisfy({ $0.actualKm == 0 }) {
                emptyChartPlaceholder(icon: "chart.bar", message: "Complete runs to see your weekly mileage")
            } else {
                Chart {
                    ForEach(weeklyMileageData) { data in
                        BarMark(
                            x: .value("Week", data.label),
                            y: .value("Planned", displayKm(data.plannedKm))
                        )
                        .foregroundStyle(Color.surgeDivider.opacity(2))
                        .cornerRadius(3)

                        BarMark(
                            x: .value("Week", data.label),
                            y: .value("Actual", displayKm(data.actualKm))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.surgeAccent, .surgeHighlight],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(3)
                    }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(Color.surgeTextSecondary)
                            .font(.system(size: 9))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.surgeDivider)
                        AxisValueLabel()
                            .foregroundStyle(Color.surgeTextSecondary)
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .surgeCard()
    }

    // MARK: - Pace Trend

    private var paceTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Pace Trend", subtitle: "Last 30 runs")

            let goalPace = PaceEngine.pace(
                finishTimeSeconds: profile.goalTimeSeconds,
                distanceKm: profile.raceType.distanceKm
            )

            Chart {
                ForEach(paceData) { point in
                    LineMark(
                        x: .value("Run", point.index),
                        y: .value("Pace", point.paceSeconds)
                    )
                    .foregroundStyle(Color.surgeAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Run", point.index),
                        y: .value("Pace", point.paceSeconds)
                    )
                    .foregroundStyle(RunTypeColor.color(for: point.runType))
                    .symbolSize(36)
                }

                if goalPace > 0 {
                    RuleMark(y: .value("Goal Pace", goalPace))
                        .foregroundStyle(Color.surgeHighlight.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .annotation(position: .trailing) {
                            Text("Goal")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.surgeHighlight)
                        }
                }
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color.surgeDivider)
                    AxisValueLabel {
                        if let seconds = value.as(Double.self) {
                            Text(PaceEngine.formatPaceShort(seconds, unit: unit))
                                .font(.system(size: 9))
                                .foregroundStyle(Color.surgeTextSecondary)
                        }
                    }
                }
            }
            .chartXAxis(.hidden)

            HStack(spacing: 16) {
                ForEach([RunType.easy, .long, .tempo, .interval], id: \.self) { type in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(RunTypeColor.color(for: type))
                            .frame(width: 8, height: 8)
                        Text(type.shortName)
                            .font(.system(size: 10))
                            .foregroundColor(.surgeTextSecondary)
                    }
                }
                Spacer()
            }
        }
        .surgeCard()
    }

    // MARK: - Long Run Progression

    private var longRunProgressionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Long Run Progression", subtitle: "Building your endurance base")

            Chart {
                ForEach(longRunData) { point in
                    BarMark(
                        x: .value("Run", point.index),
                        y: .value("Distance", displayKm(point.distanceKm))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.502, green: 0.263, blue: 0.796), .surgeAccent],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
            }
            .frame(height: 130)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color.surgeDivider)
                    AxisValueLabel {
                        if let km = value.as(Double.self) {
                            Text(unit == "mi"
                                 ? String(format: "%.0f mi", PaceEngine.kmToMiles(km))
                                 : String(format: "%.0f km", km))
                                .font(.system(size: 9))
                                .foregroundStyle(Color.surgeTextSecondary)
                        }
                    }
                }
            }

            if let longest = longRunData.max(by: { $0.distanceKm < $1.distanceKm }) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.surgeHighlight)
                        .font(.system(size: 12))
                    Text("Longest run: \(PaceEngine.formatDistance(longest.distanceKm, unit: unit))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.surgeTextSecondary)
                }
            }
        }
        .surgeCard()
    }

    // MARK: - Readiness

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SurgeSectionHeader(title: "Goal Pace Readiness")

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.surgeDivider, lineWidth: 12)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: goalPaceReadiness)
                        .stroke(
                            LinearGradient(
                                colors: [.surgeAccent, .surgeHighlight],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: goalPaceReadiness)
                    VStack(spacing: 2) {
                        Text("\(Int(goalPaceReadiness * 100))%")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.surgeTextPrimary)
                        Text("Ready")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.surgeTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity)

                let goalPace = PaceEngine.pace(
                    finishTimeSeconds: profile.goalTimeSeconds,
                    distanceKm: profile.raceType.distanceKm
                )
                VStack(spacing: 8) {
                    HStack {
                        Text("Goal Pace")
                            .font(.surgeCaption)
                            .foregroundColor(.surgeTextSecondary)
                        Spacer()
                        Text(PaceEngine.formatPace(goalPace, unit: unit))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.surgeHighlight)
                    }
                    if !paceData.isEmpty {
                        let count = min(5, paceData.count)
                        let recentAvg = paceData.suffix(count).reduce(0) { $0 + $1.paceSeconds } / Double(count)
                        HStack {
                            Text("Recent Avg")
                                .font(.surgeCaption)
                                .foregroundColor(.surgeTextSecondary)
                            Spacer()
                            Text(PaceEngine.formatPace(recentAvg, unit: unit))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.surgeAccent)
                        }
                    }
                    if runLogs.isEmpty {
                        Text("Log runs to see your readiness score")
                            .font(.surgeCaption)
                            .foregroundColor(.surgeTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .surgeCard()
    }

    // MARK: - Helpers

    private func displayKm(_ km: Double) -> Double {
        unit == "mi" ? PaceEngine.kmToMiles(km) : km
    }

    private func emptyChartPlaceholder(icon: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.surgeTextSecondary.opacity(0.3))
            Text(message)
                .font(.surgeCaption)
                .foregroundColor(.surgeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}

// MARK: - Chart Data Models

struct WeeklyMileage: Identifiable {
    let id = UUID()
    let label: String
    let actualKm: Double
    let plannedKm: Double
    let weekOffset: Int
}

struct PaceDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let paceSeconds: Double
    let date: Date
    let runType: RunType
}

struct LongRunPoint: Identifiable {
    let id = UUID()
    let index: Int
    let distanceKm: Double
}

// MARK: - Insight Card

struct InsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.surgeTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.surgeTextPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.surgeTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surgeCard()
    }
}
