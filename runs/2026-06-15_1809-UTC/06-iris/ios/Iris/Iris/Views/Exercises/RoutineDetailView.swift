import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    let routine: EyeRoutine

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var playing = false
    @State private var paywallReason: PaywallReason?

    private var unlocked: Bool { RoutineCatalog.isFree(routine) || isPro }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                exerciseList
                disclaimer
                Spacer(minLength: 8)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { startBar }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .fullScreenCover(isPresented: $playing) {
            RoutinePlayerView(routine: routine) { secs, count in
                logSession(seconds: secs, count: count)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryPill(category: routine.category)
                Spacer()
                Label(routine.totalMinutesLabel, systemImage: "clock")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text(routine.summary)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(routine.exercises.count) exercises · follow the calm focus dot, or read the cue if you prefer stillness.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Exercises", systemImage: "list.bullet")
            if routine.exercises.isEmpty {
                Text("This routine has no exercises yet.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { idx, ex in
                        exerciseRow(index: idx + 1, exercise: ex)
                    }
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    private func exerciseRow(index: Int, exercise: EyeExercise) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.accentSoft))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(exercise.name).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(exercise.seconds)s").font(Theme.mono(12, .medium)).foregroundStyle(Theme.inkFaint)
                }
                Text(exercise.instruction)
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exercise \(index): \(exercise.name), \(exercise.seconds) seconds. \(exercise.instruction)")
    }

    private var disclaimer: some View {
        Text("These are comfort exercises, not medical treatment. Stop if anything hurts and see an optometrist for vision concerns.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var startBar: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.hairline)
            Group {
                if unlocked {
                    PrimaryButton(title: "Start routine", systemImage: "play.fill") {
                        Haptics.tap(enabled: settings.hapticsEnabled)
                        playing = true
                    }
                } else {
                    PrimaryButton(title: "Unlock Iris Pro to start", systemImage: "lock.fill") {
                        paywallReason = .routineLocked
                    }
                }
            }
            .padding(16)
        }
        .background(.ultraThinMaterial)
    }

    private func logSession(seconds: Int, count: Int) {
        let session = ExerciseSession(date: .now,
                                      routineName: routine.name,
                                      durationSeconds: seconds,
                                      exercisesCompleted: count)
        modelContext.insert(session)
        modelContext.insert(BreakLog(date: .now, kind: .exercise, durationSeconds: seconds, completed: true))
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
    }
}
