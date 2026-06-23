import SwiftUI
import SwiftData

/// Train tab — the home of the app. Shows any active workout, quick-start, and
/// routine templates to launch a session fast.
struct TrainView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.finishedAt == nil },
           sort: \Workout.startedAt, order: .reverse)
    private var activeWorkouts: [Workout]
    @Query(sort: \Routine.createdAt, order: .forward) private var routines: [Routine]
    @Query private var settings: [AppSettings]

    @State private var activeWorkoutID: UUID?
    @State private var showRoutineSheet = false

    private var activeWorkout: Workout? { activeWorkouts.first }
    private var prefs: AppSettings { SettingsAccess.current(settings, context: context) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        if let active = activeWorkout {
                            activeCard(active)
                        } else {
                            quickStartCard
                        }
                        routinesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Train")
            .navigationDestination(item: $activeWorkoutID) { id in
                if let workout = activeWorkouts.first(where: { $0.id == id })
                    ?? fetchWorkout(id: id) {
                    ActiveWorkoutView(workout: workout)
                } else {
                    ContentUnavailableView("Workout not found", systemImage: "questionmark.circle")
                }
            }
            .sheet(isPresented: $showRoutineSheet) {
                RoutinePickerSheet { routine in
                    startFromRoutine(routine)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            Text("Ready to move some weight?")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private func activeCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Workout in progress", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
            }
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                HStack(spacing: 18) {
                    statBlock(Format.duration(workout.duration), "Elapsed")
                    statBlock("\(workout.completedSets.count)", "Sets")
                    statBlock(Format.volume(workout.totalVolume, unit: prefs.unit), "Volume")
                }
            }
            PrimaryButton(title: "Resume Workout", systemImage: "arrow.right") {
                activeWorkoutID = workout.id
            }
        }
        .cardSurface()
        .accessibilityElement(children: .contain)
    }

    private func statBlock(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline).foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickStartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start training")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Begin an empty session and add lifts as you go, or load a routine below.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            PrimaryButton(title: "Start Empty Workout", systemImage: "plus.circle.fill") {
                startEmptyWorkout()
            }
        }
        .cardSurface()
    }

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(text: "Routines")
                Spacer()
                Button {
                    showRoutineSheet = true
                } label: {
                    Label("All", systemImage: "square.grid.2x2")
                        .font(.caption.weight(.semibold))
                }
                .accessibilityLabel("Browse all routines")
            }
            if routines.isEmpty {
                EmptyStateCard(symbol: "rectangle.stack.badge.plus",
                               title: "No routines yet",
                               message: "Create routine templates to launch sessions instantly.")
            } else {
                ForEach(routines.prefix(5)) { routine in
                    Button {
                        startFromRoutine(routine)
                    } label: {
                        RoutineRow(routine: routine)
                    }
                    .buttonStyle(.plain)
                    .disabled(activeWorkout != nil)
                    .opacity(activeWorkout != nil ? 0.5 : 1)
                }
                if activeWorkout != nil {
                    Text("Finish your current workout before starting a routine.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Late session"
        }
    }

    // MARK: - Actions

    private func fetchWorkout(id: UUID) -> Workout? {
        let descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    private func startEmptyWorkout() {
        guard activeWorkout == nil else { return }
        Haptics.impact(.medium, enabled: prefs.hapticsEnabled)
        let workout = Workout(title: "Workout")
        context.insert(workout)
        try? context.save()
        activeWorkoutID = workout.id
    }

    private func startFromRoutine(_ routine: Routine) {
        guard activeWorkout == nil else { return }
        Haptics.impact(.medium, enabled: prefs.hapticsEnabled)
        let workout = Workout(title: routine.name)
        context.insert(workout)
        var order = 0
        for item in routine.orderedItems {
            guard let ex = item.exercise else { continue }
            for _ in 0..<item.targetSets {
                let set = SetEntry(order: order, weightKg: 0, reps: item.targetReps,
                                   isCompleted: false, workout: workout, exercise: ex)
                context.insert(set)
                workout.sets.append(set)
                order += 1
            }
        }
        try? context.save()
        showRoutineSheet = false
        activeWorkoutID = workout.id
    }
}

/// A compact routine list row.
struct RoutineRow: View {
    let routine: Routine
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: routine.colorHex))
                .frame(width: 6, height: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(routine.detail.isEmpty ? "\(routine.items.count) exercises" : routine.detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(routine.name), \(routine.items.count) exercises")
        .accessibilityHint("Starts a workout from this routine")
    }
}

/// Reusable empty-state card.
struct EmptyStateCard: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 38))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TrainView()
        .modelContainer(PersistenceController.preview)
}
