import SwiftUI
import SwiftData

/// The live workout logging screen. Group sets by exercise, add/edit/delete sets,
/// run the rest timer, detect PRs, and finish the session.
struct ActiveWorkoutView: View {
    @Bindable var workout: Workout
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var settings: [AppSettings]

    @State private var restTimer = RestTimerModel()
    @State private var showExercisePicker = false
    @State private var prBanner: PRBanner?
    @State private var showFinishConfirm = false
    @State private var showDiscardConfirm = false
    @State private var plateTarget: SetEntry?
    @State private var editingTitle = false

    private var prefs: AppSettings { SettingsAccess.current(settings, context: context) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()
            content
            if restTimer.isRunning {
                RestTimerBar(timer: restTimer, hapticsEnabled: prefs.hapticsEnabled)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Discard", role: .destructive) { showDiscardConfirm = true }
                    .tint(Theme.coral)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") { showFinishConfirm = true }
                    .fontWeight(.semibold)
                    .disabled(workout.completedSets.isEmpty)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet { exercise in
                addExercise(exercise)
            }
        }
        .sheet(item: $plateTarget) { set in
            PlateCalculatorView(initialWeightKg: set.weightKg, prefs: prefs)
        }
        .alert("Finish workout?", isPresented: $showFinishConfirm) {
            Button("Finish", role: .none) { finish() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("\(workout.completedSets.count) sets · \(Format.volume(workout.totalVolume, unit: prefs.unit)) total volume.")
        }
        .alert("Discard workout?", isPresented: $showDiscardConfirm) {
            Button("Discard", role: .destructive) { discard() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This session and its logged sets will be deleted. This can't be undone.")
        }
        .overlay(alignment: .top) {
            if let banner = prBanner {
                PRBannerView(banner: banner)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("Rename workout", isPresented: $editingTitle) {
            TextField("Workout name", text: $workout.title)
            Button("Save") { saveTitle() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryHeader
                if workout.exercises.isEmpty {
                    EmptyStateCard(symbol: "plus.rectangle.on.rectangle",
                                   title: "No lifts yet",
                                   message: "Add your first exercise to start logging sets.")
                        .padding(.top, 12)
                } else {
                    ForEach(workout.exercises) { exercise in
                        ExerciseLogCard(
                            workout: workout,
                            exercise: exercise,
                            prefs: prefs,
                            onSetCompleted: { set in handleSetCompleted(set, exercise: exercise) },
                            onPlate: { set in plateTarget = set },
                            restTimer: restTimer
                        )
                    }
                }
                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent.opacity(0.14),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, restTimer.isRunning ? 96 : 24)
        }
    }

    private var summaryHeader: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            HStack(spacing: 14) {
                summaryItem(Format.duration(workout.duration), "Time", "clock")
                Divider().frame(height: 32)
                summaryItem("\(workout.completedSets.count)", "Sets", "checkmark.circle")
                Divider().frame(height: 32)
                summaryItem(Format.volume(workout.totalVolume, unit: prefs.unit), "Volume", "scalemass")
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .cardSurface(padding: 8)
        }
        .onTapGesture { editingTitle = true }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Tap to rename this workout")
    }

    private func summaryItem(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.caption).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func addExercise(_ exercise: Exercise) {
        let nextOrder = (workout.sets.map { $0.order }.max() ?? -1) + 1
        // Pre-fill from the exercise's last completed set for a fast start.
        let last = lastCompletedSet(for: exercise)
        let set = SetEntry(order: nextOrder,
                           weightKg: last?.weightKg ?? 0,
                           reps: last?.reps ?? 8,
                           isCompleted: false,
                           workout: workout, exercise: exercise)
        context.insert(set)
        workout.sets.append(set)
        try? context.save()
        Haptics.selection(enabled: prefs.hapticsEnabled)
    }

    private func lastCompletedSet(for exercise: Exercise) -> SetEntry? {
        exercise.setEntries
            .filter { $0.isCompleted && !$0.isWarmup && ($0.workout?.id != workout.id) }
            .sorted { $0.loggedAt > $1.loggedAt }
            .first
    }

    private func handleSetCompleted(_ set: SetEntry, exercise: Exercise) {
        guard set.isCompleted else { return }
        // PR check against all OTHER sets of this exercise in finished workouts
        // plus earlier completed sets this session.
        let prior = exercise.setEntries.filter {
            $0.id != set.id && $0.isCompleted &&
            (($0.workout?.finishedAt != nil) || $0.workout?.id == workout.id)
        }
        let result = PRDetector.evaluate(candidate: set, against: prior)
        if result.isAnyPR {
            Haptics.notify(.success, enabled: prefs.hapticsEnabled)
            showPR(PRBanner(text: result.headline,
                            detail: "\(Units.weightString(kg: set.weightKg, unit: prefs.unit)) × \(set.reps)"))
        } else {
            Haptics.impact(.light, enabled: prefs.hapticsEnabled)
        }
        // Auto-start rest timer for working sets.
        if prefs.autoStartRestTimer && !set.isWarmup {
            withAnimation(reduceMotion ? nil : .spring) {
                restTimer.start(seconds: prefs.defaultRestSeconds)
            }
        }
        try? context.save()
    }

    private func showPR(_ banner: PRBanner) {
        withAnimation(reduceMotion ? nil : .spring) { prBanner = banner }
        Task {
            try? await Task.sleep(for: .seconds(2.6))
            withAnimation(reduceMotion ? nil : .easeOut) { prBanner = nil }
        }
    }

    private func saveTitle() {
        let trimmed = workout.title.trimmingCharacters(in: .whitespacesAndNewlines)
        workout.title = trimmed.isEmpty ? "Workout" : trimmed
        try? context.save()
    }

    private func finish() {
        // Drop any empty, never-completed blank sets so totals are clean.
        let empties = workout.sets.filter { !$0.isCompleted && $0.weightKg == 0 && $0.reps == 0 }
        for e in empties { context.delete(e) }
        workout.finishedAt = .now
        restTimer.stop()
        try? context.save()
        Haptics.notify(.success, enabled: prefs.hapticsEnabled)
        dismiss()
    }

    private func discard() {
        restTimer.stop()
        context.delete(workout)
        try? context.save()
        dismiss()
    }
}

struct PRBanner: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let detail: String
}

private struct PRBannerView: View {
    let banner: PRBanner
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 1) {
                Text(banner.text).font(.subheadline.bold()).foregroundStyle(.white)
                Text(banner.detail).font(.caption).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.pr, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(banner.text). \(banner.detail)")
    }
}

#Preview {
    NavigationStack {
        let container = PersistenceController.preview
        let workout = Workout(title: "Push Day")
        let _ = container.mainContext.insert(workout)
        ActiveWorkoutView(workout: workout)
            .modelContainer(container)
    }
}
