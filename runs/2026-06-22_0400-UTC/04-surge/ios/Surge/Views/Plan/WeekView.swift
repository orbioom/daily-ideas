import SwiftUI
import SwiftData

struct WeekView: View {
    let profile: RunnerProfile
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlannedRun.weekNumber) private var allPlannedRuns: [PlannedRun]
    @Query private var settings: [SurgeSettings]
    @State private var showingLogForRun: PlannedRun? = nil

    private var unit: String { settings.first?.unit ?? "km" }

    private var currentWeek: Int {
        PlanEngine.currentWeek(startDate: profile.trainingStartDate, totalWeeks: profile.totalWeeks)
    }

    private var currentDayOfWeek: Int {
        PlanEngine.currentDayOfWeek()
    }

    private var thisWeekRuns: [PlannedRun] {
        allPlannedRuns
            .filter { $0.weekNumber == currentWeek }
            .sorted { $0.dayOfWeek < $1.dayOfWeek }
    }

    private let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Week stats
                    weekStatsView
                        .padding(.horizontal, 16)

                    // Day by day
                    ForEach(thisWeekRuns) { run in
                        let isToday = run.dayOfWeek == currentDayOfWeek
                        VStack(alignment: .leading, spacing: 0) {
                            if isToday {
                                Text("TODAY")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.surgeHighlight)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 6)
                                    .tracking(1.5)
                            }
                            WeekDayRow(
                                dayName: dayNames[run.dayOfWeek],
                                date: PlanEngine.date(for: currentWeek, dayOfWeek: run.dayOfWeek, startDate: profile.trainingStartDate),
                                run: run,
                                unit: unit,
                                onMarkDone: { markDone(run) },
                                onLog: { showingLogForRun = run }
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
                .padding(.bottom, 32)
            }
            .background(Color.surgeBackground.ignoresSafeArea())
            .navigationTitle("Week \(currentWeek)")
        }
        .sheet(item: $showingLogForRun) { run in
            LogRunView(linkedPlannedRun: run, unit: unit)
        }
    }

    private var weekStatsView: some View {
        let totalKm = thisWeekRuns.reduce(0) { $0 + $1.distanceKm }
        let completedKm = thisWeekRuns.filter { $0.isCompleted }.reduce(0) { $0 + $1.distanceKm }
        let remainingKm = totalKm - completedKm

        return HStack(spacing: 0) {
            StatBadge(
                label: "Total",
                value: PaceEngine.formatDistance(totalKm, unit: unit),
                color: .surgeTextPrimary
            )
            Divider().background(Color.surgeDivider)
            StatBadge(
                label: "Done",
                value: PaceEngine.formatDistance(completedKm, unit: unit),
                color: .surgeSuccess
            )
            Divider().background(Color.surgeDivider)
            StatBadge(
                label: "Left",
                value: PaceEngine.formatDistance(remainingKm, unit: unit),
                color: .surgeHighlight
            )
        }
        .frame(height: 72)
        .surgeCard(padding: 0)
    }

    private func markDone(_ run: PlannedRun) {
        run.isCompleted = true
        run.completedDate = Date()
        let log = RunLog(
            date: Date(),
            distanceKm: run.distanceKm,
            durationSeconds: run.paceTargetSecondsPerKm > 0 ? PaceEngine.finishTime(paceSecondsPerKm: run.paceTargetSecondsPerKm, distanceKm: run.distanceKm) : 0,
            perceivedEffort: 3,
            runType: run.runType,
            linkedPlanRunId: run.id
        )
        modelContext.insert(log)
        try? modelContext.save()
    }
}
