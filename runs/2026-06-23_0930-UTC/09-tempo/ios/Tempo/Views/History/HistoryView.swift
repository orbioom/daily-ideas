import SwiftUI
import SwiftData

/// History tab — finished workouts grouped by month, with totals and detail drill-in.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.finishedAt != nil },
           sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    @Query private var settings: [AppSettings]

    private var prefs: AppSettings { SettingsAccess.current(settings, context: context) }

    private var grouped: [(title: String, workouts: [Workout])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: workouts) { w -> Date in
            cal.dateInterval(of: .month, for: w.startedAt)?.start ?? w.startedAt
        }
        return dict.keys.sorted(by: >).map { key in
            (Format.monthTitle(key), (dict[key] ?? []).sorted { $0.startedAt > $1.startedAt })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No workouts yet", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Finished sessions show up here with volume, duration, and PRs.")
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            summaryStrip
                            ForEach(grouped, id: \.title) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    SectionLabel(text: group.title)
                                    ForEach(group.workouts) { workout in
                                        NavigationLink(value: workout.id) {
                                            HistoryRow(workout: workout, prefs: prefs)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: UUID.self) { id in
                if let workout = workouts.first(where: { $0.id == id }) {
                    WorkoutDetailView(workout: workout, prefs: prefs)
                } else {
                    ContentUnavailableView("Workout removed", systemImage: "trash")
                }
            }
        }
    }

    private var summaryStrip: some View {
        let engine = StatsEngine(workouts: workouts)
        return HStack(spacing: 12) {
            MetricTile(title: "Workouts", value: "\(engine.totalWorkouts)",
                       systemImage: "checkmark.seal.fill", tint: Theme.success)
            MetricTile(title: "Week streak", value: "\(engine.weekStreak)",
                       systemImage: "flame.fill", tint: Theme.accent)
        }
    }
}

struct HistoryRow: View {
    let workout: Workout
    let prefs: AppSettings
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.title).font(.headline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(Format.dayTitle(workout.startedAt))
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            HStack(spacing: 16) {
                stat("scalemass", Format.volume(workout.totalVolume, unit: prefs.unit))
                stat("checkmark.circle", "\(workout.completedSets.count) sets")
                stat("clock", Format.duration(workout.duration))
            }
            if !workout.exercises.isEmpty {
                Text(workout.exercises.prefix(4).map { $0.name }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.title), \(Format.dayTitle(workout.startedAt)), \(workout.completedSets.count) sets, \(Format.volume(workout.totalVolume, unit: prefs.unit))")
    }

    private func stat(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
            .labelStyle(.titleAndIcon)
    }
}

#Preview {
    HistoryView().modelContainer(PersistenceController.preview)
}
