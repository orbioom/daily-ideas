import SwiftUI
import SwiftData
import Charts

/// Per-exercise detail: PR cards, estimated-1RM trend chart, and recent history.
struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    let prefs: AppSettings
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.finishedAt != nil },
           sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]

    @State private var showEditor = false

    private var engine: StatsEngine { StatsEngine(workouts: workouts) }
    private var trend: [StatsEngine.OneRepMaxPoint] { engine.oneRepMaxTrend(for: exercise) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    prCards
                    trendCard
                    historyCard
                    if !exercise.notes.isEmpty { notesCard }
                }
                .padding(16)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { toggleFavorite() } label: {
                        Label(exercise.isFavorite ? "Unfavorite" : "Favorite",
                              systemImage: exercise.isFavorite ? "star.slash" : "star")
                    }
                    if exercise.isCustom {
                        Button { showEditor = true } label: { Label("Edit", systemImage: "pencil") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Exercise options")
            }
        }
        .sheet(isPresented: $showEditor) {
            ExerciseEditorView(existing: exercise)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: exercise.muscle.symbol)
                .font(.largeTitle).foregroundStyle(Theme.accent).frame(width: 52)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    TagPill(text: exercise.muscle.display, systemImage: "target", tint: Theme.accent)
                    TagPill(text: exercise.equipment.display, tint: Theme.volume)
                }
                if exercise.isFavorite {
                    Label("Favorite", systemImage: "star.fill").font(.caption).foregroundStyle(Theme.pr)
                }
            }
            Spacer()
        }
        .cardSurface()
    }

    private var prCards: some View {
        let best1RM = engine.bestOneRepMax(for: exercise)
        let bestWeight = engine.bestWeight(for: exercise)
        return HStack(spacing: 12) {
            MetricTile(title: "Est. 1RM",
                       value: best1RM.map { Units.weightString(kg: $0, unit: prefs.unit) } ?? "—",
                       systemImage: "trophy.fill", tint: Theme.pr)
            MetricTile(title: "Top weight",
                       value: bestWeight.map { Units.weightString(kg: $0, unit: prefs.unit) } ?? "—",
                       systemImage: "scalemass.fill", tint: Theme.accent)
        }
    }

    @ViewBuilder
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Estimated 1RM trend")
            if trend.count < 2 {
                Text("Log this lift in at least two sessions to see your strength trend.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                    .multilineTextAlignment(.center)
            } else {
                Chart(trend) { point in
                    LineMark(x: .value("Date", point.date),
                             y: .value("e1RM", Units.display(fromKg: point.valueKg, unit: prefs.unit)))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent)
                    AreaMark(x: .value("Date", point.date),
                             y: .value("e1RM", Units.display(fromKg: point.valueKg, unit: prefs.unit)))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.3), .clear],
                                                        startPoint: .top, endPoint: .bottom))
                    PointMark(x: .value("Date", point.date),
                              y: .value("e1RM", Units.display(fromKg: point.valueKg, unit: prefs.unit)))
                        .foregroundStyle(Theme.accent)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 180)
                .accessibilityLabel("Estimated one rep max trend over \(trend.count) sessions")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var historyCard: some View {
        let recent = workouts.flatMap { w in w.sets(for: exercise).map { (w, $0) } }
            .filter { !$0.1.isWarmup && $0.1.isCompleted }
            .sorted { $0.1.loggedAt > $1.1.loggedAt }
            .prefix(8)
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Recent sets")
            if recent.isEmpty {
                Text("No logged sets yet for this lift.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(Array(recent), id: \.1.id) { pair in
                    HStack {
                        Text(Format.dayTitle(pair.0.startedAt))
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                            .frame(width: 90, alignment: .leading)
                        Text("\(Units.weightString(kg: pair.1.weightKg, unit: prefs.unit)) × \(pair.1.reps)")
                            .font(.subheadline.weight(.medium)).foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if let e = pair.1.estimatedOneRepMax {
                            Text("e1RM \(Units.weightString(kg: e, unit: prefs.unit, showUnit: false))")
                                .font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "Notes")
            Text(exercise.notes).font(.subheadline).foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func toggleFavorite() {
        exercise.isFavorite.toggle()
        try? context.save()
        Haptics.selection(enabled: prefs.hapticsEnabled)
    }
}
