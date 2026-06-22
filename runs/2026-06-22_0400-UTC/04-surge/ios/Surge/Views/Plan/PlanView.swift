import SwiftUI
import SwiftData

struct PlanView: View {
    let profile: RunnerProfile
    @Query(sort: \PlannedRun.weekNumber) private var allPlannedRuns: [PlannedRun]
    @Query private var settings: [SurgeSettings]
    @State private var selectedWeek: Int? = nil

    private var unit: String { settings.first?.unit ?? "km" }

    private var currentWeek: Int {
        PlanEngine.currentWeek(startDate: profile.trainingStartDate, totalWeeks: profile.totalWeeks)
    }

    private var weekGroups: [[PlannedRun]] {
        (1...profile.totalWeeks).map { week in
            allPlannedRuns.filter { $0.weekNumber == week }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10, pinnedViews: []) {
                    // Plan summary header
                    planHeader
                        .padding(.horizontal, 16)

                    // Run type legend
                    legendView
                        .padding(.horizontal, 16)

                    // Weeks
                    ForEach(0..<weekGroups.count, id: \.self) { weekIndex in
                        let weekNumber = weekIndex + 1
                        let weekRuns = weekGroups[weekIndex]
                        WeekRowView(
                            weekNumber: weekNumber,
                            runs: weekRuns,
                            isCurrentWeek: weekNumber == currentWeek,
                            unit: unit,
                            startDate: profile.trainingStartDate,
                            onTap: { selectedWeek = weekNumber }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.surgeBackground.ignoresSafeArea())
            .navigationTitle("Training Plan")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: Binding(
            get: { selectedWeek.map { WeekSelection(week: $0) } },
            set: { selectedWeek = $0?.week }
        )) { selection in
            WeekDetailView(
                weekNumber: selection.week,
                runs: allPlannedRuns.filter { $0.weekNumber == selection.week },
                startDate: profile.trainingStartDate,
                unit: unit
            )
        }
    }

    private var planHeader: some View {
        HStack(spacing: 0) {
            StatBadge(
                label: profile.raceType.displayName,
                value: "\(profile.totalWeeks)wk",
                color: .surgeHighlight
            )
            Divider().background(Color.surgeDivider)
            StatBadge(
                label: "Goal Time",
                value: PaceEngine.formatGoalTime(profile.goalTimeSeconds),
                color: .surgeAccent
            )
            Divider().background(Color.surgeDivider)
            StatBadge(
                label: "Goal Pace",
                value: PaceEngine.formatPaceShort(PaceEngine.pace(finishTimeSeconds: profile.goalTimeSeconds, distanceKm: profile.raceType.distanceKm), unit: unit),
                color: .surgeTextPrimary
            )
        }
        .frame(height: 72)
        .surgeCard(padding: 0)
    }

    private var legendView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RunType.allCases.filter { $0 != .rest }, id: \.self) { type in
                    RunTypeBadge(runType: type, style: .standard)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct WeekSelection: Identifiable {
    let id = UUID()
    let week: Int
}

struct WeekRowView: View {
    let weekNumber: Int
    let runs: [PlannedRun]
    let isCurrentWeek: Bool
    let unit: String
    let startDate: Date
    var onTap: () -> Void

    private var weekStartDate: Date {
        PlanEngine.date(for: weekNumber, dayOfWeek: 0, startDate: startDate)
    }

    private var totalKm: Double {
        runs.reduce(0) { $0 + $1.distanceKm }
    }

    private var completedKm: Double {
        runs.filter { $0.isCompleted }.reduce(0) { $0 + $1.distanceKm }
    }

    private var completionRatio: Double {
        guard totalKm > 0 else { return 0 }
        return completedKm / totalKm
    }

    private var weekPhase: String {
        guard let total = runs.first.map({ _ in runs.count }) else { return "" }
        let _ = total
        if weekNumber <= 3 { return "Base" }
        if weekNumber == 4 || weekNumber == 8 || weekNumber == 12 { return "Recovery" }
        if weekNumber >= 14 { return "Taper" }
        return "Build"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("Week \(weekNumber)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(isCurrentWeek ? .surgeHighlight : .surgeTextPrimary)
                            if isCurrentWeek {
                                Text("NOW")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.surgeBackground)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.surgeHighlight)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(weekStartDate, format: .dateTime.month(.abbreviated).day())
                            .font(.surgeCaption)
                            .foregroundColor(.surgeTextSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(PaceEngine.formatDistance(totalKm, unit: unit))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.surgeTextPrimary)
                        if !weekPhase.isEmpty {
                            Text(weekPhase)
                                .font(.surgeCaption)
                                .foregroundColor(.surgeTextSecondary)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.surgeTextSecondary.opacity(0.5))
                        .padding(.leading, 4)
                }

                // Mini weekly grid
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { day in
                        let run = runs.first(where: { $0.dayOfWeek == day })
                        MiniDayDot(run: run)
                    }
                }

                // Progress bar if any completed
                if completionRatio > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.surgeDivider)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.surgeSuccess)
                                .frame(width: geo.size.width * completionRatio)
                        }
                    }
                    .frame(height: 3)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.surgeSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isCurrentWeek ? Color.surgeHighlight.opacity(0.4) : Color.surgeDivider, lineWidth: isCurrentWeek ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct MiniDayDot: View {
    let run: PlannedRun?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(dotColor)
                .frame(height: 18)

            if let run = run, run.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dotColor: Color {
        guard let run = run else { return Color.surgeDivider }
        if run.isCompleted { return .surgeSuccess }
        if run.type == .rest { return Color.surgeDivider }
        return RunTypeColor.color(for: run.type).opacity(0.5)
    }
}
