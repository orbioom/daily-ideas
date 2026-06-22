import SwiftUI
import SwiftData

struct TodayView: View {
    let profile: RunnerProfile
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlannedRun.weekNumber) private var allPlannedRuns: [PlannedRun]
    @Query private var settings: [SurgeSettings]

    @State private var showingLogRun: Bool = false
    @State private var selectedRunForLogging: PlannedRun? = nil

    private var unit: String { settings.first?.unit ?? "km" }

    private var currentWeek: Int {
        PlanEngine.currentWeek(startDate: profile.trainingStartDate, totalWeeks: profile.totalWeeks)
    }

    private var currentDayOfWeek: Int {
        PlanEngine.currentDayOfWeek()
    }

    private var thisWeekRuns: [PlannedRun] {
        allPlannedRuns.filter { $0.weekNumber == currentWeek }
    }

    private var nextWeekRuns: [PlannedRun] {
        allPlannedRuns.filter { $0.weekNumber == currentWeek + 1 }
    }

    private var todaysRun: PlannedRun? {
        thisWeekRuns.first(where: { $0.dayOfWeek == currentDayOfWeek })
    }

    private var weekCompletionRatio: Double {
        let running = thisWeekRuns.filter { $0.type.isRunningWorkout }
        guard !running.isEmpty else { return 0 }
        let completed = running.filter { $0.isCompleted }.count
        return Double(completed) / Double(running.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with countdown
                    headerView

                    // Today's workout
                    todaySection

                    // This week overview
                    weekOverviewSection

                    // Next week preview
                    if currentWeek < profile.totalWeeks {
                        nextWeekPreview
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.surgeBackground.ignoresSafeArea())
            .navigationTitle("Surge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SURGE")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.surgeHighlight)
                        .tracking(2)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .foregroundColor(.surgeTextSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingLogRun) {
            if let run = selectedRunForLogging {
                LogRunView(linkedPlannedRun: run, unit: unit)
            } else {
                LogRunView(unit: unit)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(), format: .dateTime.weekday(.wide).month().day())
                    .font(.surgeCaption)
                    .foregroundColor(.surgeTextSecondary)
                    .textCase(.uppercase)
                Text("Week \(currentWeek) of \(profile.totalWeeks)")
                    .font(.surgeHeadline)
                    .foregroundColor(.surgeTextPrimary)
            }

            Spacer()

            if let days = profile.daysUntilRace, days >= 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(days)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.surgeHighlight)
                    Text("days to race")
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                }
            }
        }
        .padding(16)
        .surgeCard()
    }

    // MARK: - Today Section

    @ViewBuilder
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Today's Workout")

            if let run = todaysRun {
                WorkoutCard(
                    run: run,
                    unit: unit,
                    onMarkDone: { markDone(run) },
                    onLogRun: {
                        selectedRunForLogging = run
                        showingLogRun = true
                    },
                    isHighlighted: true
                )
            } else {
                EmptyWorkoutView()
            }
        }
    }

    // MARK: - Week Overview

    private var weekOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SurgeSectionHeader(title: "This Week")
                Spacer()
                // Week mileage
                let totalKm = thisWeekRuns.reduce(0) { $0 + $1.distanceKm }
                Text(PaceEngine.formatDistance(totalKm, unit: unit))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.surgeHighlight)
            }

            WeeklyGrid(
                plannedRuns: thisWeekRuns,
                currentDayOfWeek: currentDayOfWeek,
                onTapDay: { run in
                    selectedRunForLogging = run
                    showingLogRun = run.type.isRunningWorkout
                }
            )
            .padding(12)
            .surgeCard(padding: 0)

            // Progress bar
            VStack(spacing: 6) {
                HStack {
                    Text("Week Progress")
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                    Spacer()
                    let completed = thisWeekRuns.filter { $0.isCompleted && $0.type.isRunningWorkout }.count
                    let total = thisWeekRuns.filter { $0.type.isRunningWorkout }.count
                    Text("\(completed)/\(total) runs done")
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.surgeDivider)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.surgeAccent, .surgeHighlight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * weekCompletionRatio)
                    }
                    .frame(height: 6)
                }
                .frame(height: 6)
            }
        }
    }

    // MARK: - Next Week Preview

    private var nextWeekPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Next Week Preview")

            let totalKm = nextWeekRuns.reduce(0) { $0 + $1.distanceKm }
            HStack {
                WeeklyGrid(
                    plannedRuns: nextWeekRuns,
                    currentDayOfWeek: -1
                )
                VStack(alignment: .trailing, spacing: 4) {
                    Text(PaceEngine.formatDistance(totalKm, unit: unit))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.surgeTextPrimary)
                    Text("total")
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                }
                .padding(.leading, 8)
            }
            .padding(12)
            .surgeCard(padding: 0)
        }
    }

    // MARK: - Actions

    private func markDone(_ run: PlannedRun) {
        run.isCompleted = true
        run.completedDate = Date()

        // Also create a RunLog entry
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

struct EmptyWorkoutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 36))
                .foregroundColor(.surgeTextSecondary.opacity(0.5))
            Text("Rest Day")
                .font(.surgeHeadline)
                .foregroundColor(.surgeTextPrimary)
            Text("Recovery is part of training. Take it easy today.")
                .font(.surgeBody)
                .foregroundColor(.surgeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .surgeCard()
    }
}
