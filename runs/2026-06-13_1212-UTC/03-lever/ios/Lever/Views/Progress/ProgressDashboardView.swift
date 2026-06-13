import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]
    @Query private var progressRecords: [ExerciseProgress]

    @State private var chartExerciseID = ExerciseLibrary.all[0].id

    private var stats: TrainingStats { TrainingStats.from(logs, progress: progressRecords) }
    private var chartExercise: Exercise {
        ExerciseLibrary.byID(chartExerciseID) ?? ExerciseLibrary.all[0]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if logs.isEmpty {
                    EmptyStateView(icon: "chart.bar.fill",
                                   title: "No sessions yet",
                                   message: "Run a guided session from the Train tab and your streak, volume and levels will land here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statsGrid
                            volumeChart
                            weekChart
                            levelTiles
                            recentList
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(stats.currentStreak)", label: "Day streak")
            StatTile(value: "\(stats.totalSessions)", label: "Sessions", accent: Theme.good)
            StatTile(value: "\(stats.totalReps)", label: "Total reps", accent: Theme.ink)
            StatTile(value: "\(stats.levelsClimbed)", label: "Levels climbed")
            StatTile(value: "\(stats.longestStreak)", label: "Longest streak", accent: Theme.ink)
            StatTile(value: "\(progressRecords.count)", label: "Movements", accent: Theme.good)
        }
    }

    private var volumeSeries: [VolumePoint] {
        TrainingStats.volumeSeries(logs, exerciseID: chartExerciseID)
    }

    private var volumeChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Volume over time", systemImage: "chart.line.uptrend.xyaxis")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Spacer()
                    Picker("Movement", selection: $chartExerciseID) {
                        ForEach(ExerciseLibrary.all) { Text($0.name).tag($0.id) }
                    }
                    .pickerStyle(.menu).tint(Theme.accent)
                }
                if volumeSeries.isEmpty {
                    Text("No \(chartExercise.name) sessions logged yet.")
                        .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart(volumeSeries) { p in
                        LineMark(x: .value("Date", p.date), y: .value("Volume", p.volume))
                            .foregroundStyle(Theme.accent)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", p.date), y: .value("Volume", p.volume))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(height: 160)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .accessibilityLabel("Volume over time for \(chartExercise.name)")
                }
            }
        }
    }

    private var weekSeries: [WeekCount] { TrainingStats.sessionsPerWeek(logs) }

    @ViewBuilder private var weekChart: some View {
        if !weekSeries.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Sessions per week", systemImage: "calendar")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Chart(weekSeries) { w in
                        BarMark(x: .value("Week", w.weekStart, unit: .weekOfYear),
                                y: .value("Sessions", w.count))
                            .foregroundStyle(Theme.good)
                    }
                    .frame(height: 150)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .accessibilityLabel("Sessions per week")
                }
            }
        }
    }

    private var levelTiles: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Where you stand").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                ForEach(Array(ExerciseLibrary.all.enumerated()), id: \.offset) { idx, exercise in
                    let rec = ProgressStore.find(exercise.id, in: progressRecords)
                    HStack(spacing: 12) {
                        ExerciseGlyph(exercise: exercise, size: 32)
                        Text(exercise.name).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Lvl \(((rec?.currentLevel) ?? 0) + 1)")
                                .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.accent)
                            Text("best \(rec?.bestResult ?? 0) \(exercise.unit.short)")
                                .font(Theme.rounded(11, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    if idx < ExerciseLibrary.all.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }

    private var recentList: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent sessions").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let recent = Array(logs.prefix(12))
                ForEach(Array(recent.enumerated()), id: \.offset) { idx, log in
                    let exercise = ExerciseLibrary.byID(log.exerciseID)
                    HStack(spacing: 12) {
                        Image(systemName: exercise?.icon ?? "bolt.fill")
                            .foregroundStyle(Theme.accent).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise?.name ?? "Workout")
                                .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                            Text("Level \(log.levelIndex + 1) · \(Fmt.relativeDay(log.date))")
                                .font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text("\(log.totalVolume) \(exercise?.unit.short ?? "")")
                            .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityElement(children: .combine)
                    if idx < recent.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }
}
