import SwiftUI
import SwiftData

struct WeekDetailView: View {
    let weekNumber: Int
    let runs: [PlannedRun]
    let startDate: Date
    let unit: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingLogForRun: PlannedRun? = nil

    private let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    private var sortedRuns: [PlannedRun] {
        runs.sorted { $0.dayOfWeek < $1.dayOfWeek }
    }

    private var totalKm: Double {
        runs.reduce(0) { $0 + $1.distanceKm }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Week summary
                    HStack(spacing: 0) {
                        StatBadge(
                            label: "Total",
                            value: PaceEngine.formatDistance(totalKm, unit: unit),
                            color: .surgeHighlight
                        )
                        Divider().background(Color.surgeDivider)
                        StatBadge(
                            label: "Runs",
                            value: "\(runs.filter { $0.type.isRunningWorkout }.count)",
                            color: .surgeAccent
                        )
                        Divider().background(Color.surgeDivider)
                        let completed = runs.filter { $0.isCompleted }.count
                        StatBadge(
                            label: "Done",
                            value: "\(completed)",
                            color: .surgeSuccess
                        )
                    }
                    .frame(height: 72)
                    .surgeCard(padding: 0)
                    .padding(.horizontal, 16)

                    // Daily runs
                    ForEach(sortedRuns) { run in
                        WeekDayRow(
                            dayName: dayNames[run.dayOfWeek],
                            date: PlanEngine.date(for: weekNumber, dayOfWeek: run.dayOfWeek, startDate: startDate),
                            run: run,
                            unit: unit,
                            onMarkDone: { markDone(run) },
                            onLog: { showingLogForRun = run }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
                .padding(.bottom, 32)
            }
            .background(Color.surgeBackground.ignoresSafeArea())
            .navigationTitle("Week \(weekNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.surgeAccent)
                }
            }
        }
        .sheet(item: $showingLogForRun) { run in
            LogRunView(linkedPlannedRun: run, unit: unit)
        }
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

struct WeekDayRow: View {
    let dayName: String
    let date: Date
    let run: PlannedRun
    let unit: String
    var onMarkDone: () -> Void
    var onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.surgeTextPrimary)
                    Text(date, format: .dateTime.month(.abbreviated).day())
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                }

                Spacer()

                RunTypeBadge(runType: run.type, style: .standard)

                if run.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.surgeSuccess)
                        .font(.system(size: 20))
                }
            }

            if run.type.isRunningWorkout && run.distanceKm > 0 {
                HStack(spacing: 12) {
                    Label(PaceEngine.formatDistance(run.distanceKm, unit: unit), systemImage: "map")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.surgeTextSecondary)

                    if run.paceTargetSecondsPerKm > 0 {
                        Label(PaceEngine.formatPace(run.paceTargetSecondsPerKm, unit: unit), systemImage: "speedometer")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.surgeTextSecondary)
                    }
                }

                if !run.notes.isEmpty {
                    Text(run.notes)
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                        .padding(.top, 2)
                }

                if !run.isCompleted {
                    HStack(spacing: 8) {
                        Button(action: onMarkDone) {
                            Label("Mark Done", systemImage: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.surgeSuccess)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.surgeSuccess.opacity(0.12))
                        .clipShape(Capsule())

                        Button(action: onLog) {
                            Label("Log Run", systemImage: "square.and.pencil")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.surgeAccent)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.surgeAccent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            } else if run.type == .crossTrain {
                Text(run.notes)
                    .font(.surgeCaption)
                    .foregroundColor(.surgeTextSecondary)
            } else if run.type == .rest {
                Text("Recovery day — let your body repair and rebuild")
                    .font(.surgeCaption)
                    .foregroundColor(.surgeTextSecondary)
            }
        }
        .surgeCard()
        .opacity(run.isCompleted ? 0.7 : 1.0)
    }
}
