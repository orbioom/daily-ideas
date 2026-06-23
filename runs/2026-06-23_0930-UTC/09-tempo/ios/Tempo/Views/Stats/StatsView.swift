import SwiftUI
import SwiftData
import Charts

/// Stats tab — training overview: headline metrics, weekly volume, estimated-1RM
/// trend for a chosen lift, muscle-group split, plus a link to manage routines.
struct StatsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.finishedAt != nil },
           sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query private var settings: [AppSettings]

    @State private var selectedExerciseID: UUID?

    private var prefs: AppSettings { SettingsAccess.current(settings, context: context) }
    private var engine: StatsEngine { StatsEngine(workouts: workouts) }

    private var trackedExercises: [Exercise] {
        exercises.filter { ex in workouts.contains { !$0.sets(for: ex).isEmpty } }
            .sorted { $0.name < $1.name }
    }

    private var selectedExercise: Exercise? {
        trackedExercises.first { $0.id == selectedExerciseID } ?? trackedExercises.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No stats yet", systemImage: "chart.xyaxis.line")
                    } description: {
                        Text("Finish a workout to unlock volume trends, PRs, and your muscle-group split.")
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            metricsGrid
                            volumeChart
                            oneRepMaxChart
                            muscleSplit
                            routinesLink
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationDestination(for: StatsRoute.self) { route in
                switch route {
                case .routines: RoutinesManagerView(prefs: prefs)
                }
            }
        }
    }

    private var metricsGrid: some View {
        let grid = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: grid, spacing: 12) {
            MetricTile(title: "Workouts", value: "\(engine.totalWorkouts)",
                       systemImage: "checkmark.seal.fill", tint: Theme.success)
            MetricTile(title: "Week streak", value: "\(engine.weekStreak)",
                       systemImage: "flame.fill", tint: Theme.accent)
            MetricTile(title: "Total volume",
                       value: Format.volume(engine.totalVolumeKg, unit: prefs.unit),
                       systemImage: "scalemass.fill", tint: Theme.volume)
            MetricTile(title: "Sets logged", value: "\(engine.totalSets)",
                       systemImage: "list.number", tint: Theme.rest)
        }
    }

    private var volumeChart: some View {
        let data = engine.weeklyVolume(weeks: 8)
        return VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Weekly volume · last 8 weeks")
            Chart(data) { point in
                BarMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Volume", Units.display(fromKg: point.volumeKg, unit: prefs.unit))
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(5)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Weekly training volume over the last 8 weeks")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    @ViewBuilder
    private var oneRepMaxChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(text: "Estimated 1RM")
                Spacer()
                if !trackedExercises.isEmpty {
                    Picker("Exercise", selection: Binding(
                        get: { selectedExercise?.id },
                        set: { selectedExerciseID = $0 }
                    )) {
                        ForEach(trackedExercises) { Text($0.name).tag(Optional($0.id)) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)
                }
            }
            if let ex = selectedExercise {
                let trend = engine.oneRepMaxTrend(for: ex)
                if trend.count < 2 {
                    Text("Need two or more sessions of \(ex.name) to chart a trend.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart(trend) { point in
                        LineMark(x: .value("Date", point.date),
                                 y: .value("e1RM", Units.display(fromKg: point.valueKg, unit: prefs.unit)))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.pr)
                        PointMark(x: .value("Date", point.date),
                                  y: .value("e1RM", Units.display(fromKg: point.valueKg, unit: prefs.unit)))
                            .foregroundStyle(Theme.pr)
                    }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: 180)
                    .accessibilityLabel("Estimated one rep max trend for \(ex.name)")
                }
            } else {
                Text("Log some sets to see strength trends.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var muscleSplit: some View {
        let data = engine.volumeByMuscle(days: 30)
        return VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Muscle split · last 30 days")
            if data.isEmpty {
                Text("No working volume logged in the last 30 days.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Volume", Units.display(fromKg: point.volumeKg, unit: prefs.unit)),
                        y: .value("Muscle", point.muscle.display)
                    )
                    .foregroundStyle(Theme.volume.gradient)
                    .cornerRadius(5)
                }
                .chartXAxis { AxisMarks(position: .bottom) }
                .frame(height: CGFloat(data.count) * 34 + 20)
                .accessibilityLabel("Training volume by muscle group over the last 30 days")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var routinesLink: some View {
        NavigationLink(value: StatsRoute.routines) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title3).foregroundStyle(Theme.accent).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manage Routines").font(.headline).foregroundStyle(Theme.textPrimary)
                    Text("Build Push / Pull / Legs templates").font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens routine management")
    }
}

enum StatsRoute: Hashable { case routines }

#Preview {
    StatsView().modelContainer(PersistenceController.preview)
}
