import SwiftUI
import SwiftData

/// The training log: every session, newest first.
struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue

    @State private var navTarget: Workout?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if workouts.isEmpty {
                        EmptyStateView(icon: "figure.strengthtraining.traditional",
                                       title: "No sessions yet",
                                       message: "Start a workout to log your first sets.")
                    } else { list }
                }
            }
            .navigationTitle("Training")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startWorkout() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New workout")
                }
            }
            .navigationDestination(for: Workout.self) { WorkoutDetailView(workout: $0) }
            .navigationDestination(item: $navTarget) { WorkoutDetailView(workout: $0) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                weekStrip
                ForEach(workouts) { w in
                    NavigationLink(value: w) { WorkoutRow(workout: w, unit: unit) }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { delete(w) } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private var weekStrip: some View {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = workouts.filter { $0.date >= weekAgo }
        let vol = recent.reduce(0.0) { $0 + $1.volumeKg }
        return HStack(spacing: 10) {
            StatTile(value: "\(recent.count)", label: "This week")
            StatTile(value: Fmt.volume(vol, unit: unit), label: "Volume / 7d", tint: Brand.live)
            StatTile(value: "\(workouts.count)", label: "All time")
        }
    }

    private func startWorkout() {
        let w = Workout(date: Date(), title: defaultTitle())
        context.insert(w)
        navTarget = w
        Haptics.tap()
    }
    private func defaultTitle() -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE"
        return f.string(from: Date()) + " session"
    }
    private func delete(_ w: Workout) { context.delete(w); try? context.save(); Haptics.warning() }
}

private struct WorkoutRow: View {
    let workout: Workout
    let unit: WeightUnit
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.title.isEmpty ? "Session" : workout.title)
                        .font(.headline).foregroundStyle(Brand.text)
                    Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
                Spacer()
                Text(Fmt.volume(workout.volumeKg, unit: unit))
                    .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
            }
            let names = workout.exercisesInOrder.prefix(4).map(\.name)
            if names.isEmpty {
                Text("No sets logged").font(.caption).foregroundStyle(Brand.text3)
            } else {
                HStack(spacing: 6) {
                    ForEach(names, id: \.self) { Pill(text: $0) }
                    if workout.exercisesInOrder.count > 4 {
                        Pill(text: "+\(workout.exercisesInOrder.count - 4)")
                    }
                }
            }
        }
        .glassCard()
    }
}
