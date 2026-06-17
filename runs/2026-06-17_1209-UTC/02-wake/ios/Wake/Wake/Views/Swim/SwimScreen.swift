import SwiftUI
import SwiftData

/// The Swim tab: choose a template or free-swim, then launch the guided runner.
struct SwimScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SwimWorkout.createdAt, order: .reverse) private var workouts: [SwimWorkout]
    @AppStorage(PrefKey.poolLengthRaw) private var poolLengthRaw = PoolLength.scm25.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true

    @State private var activeRunner: SwimRunner?
    @State private var showFreeSwimSetup = false

    private var poolLength: PoolLength { PoolLength(rawValue: poolLengthRaw) ?? .scm25 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        hero
                        freeSwimCard
                        templatesSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Swim")
            .fullScreenCover(item: $activeRunner) { runner in
                SwimRunnerView(runner: runner)
            }
            .sheet(isPresented: $showFreeSwimSetup) {
                FreeSwimSetupView(poolLength: poolLength) { reps in
                    launch(reps: reps, name: nil, isFree: true)
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready to dive in?")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(.white)
            Text("Pick a workout to follow with the interval clock, or log a free swim.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Pill(text: poolLength.shortLabel, color: .white, systemImage: "ruler")
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.waterGradient)
        )
    }

    private var freeSwimCard: some View {
        Button {
            Haptics.tap(hapticsEnabled)
            showFreeSwimSetup = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free swim")
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Open clock — log distance as you go")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Start an unstructured swim")
    }

    @ViewBuilder
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start a workout")
                .font(Theme.rounded(18, .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            if workouts.isEmpty {
                EmptyStateView(symbol: "list.bullet.rectangle",
                               title: "No workouts yet",
                               message: "Built-in workouts load automatically. Visit the Workouts tab to build your own.")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(workouts) { workout in
                        Button {
                            Haptics.select(hapticsEnabled)
                            let reps = SwimRunner.reps(from: workout)
                            launch(reps: reps, name: workout.name, isFree: false, pool: workout.poolLengthMeters)
                        } label: {
                            WorkoutStartRow(workout: workout)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func launch(reps: [RunnerRep], name: String?, isFree: Bool, pool: Double? = nil) {
        guard !reps.isEmpty else { return }
        let length = pool ?? poolLength.meters
        activeRunner = SwimRunner(reps: reps,
                                  poolLengthMeters: length,
                                  workoutName: name,
                                  isFreeSwim: isFree)
    }
}

/// Compact row used in the Swim tab to start a workout.
private struct WorkoutStartRow: View {
    let workout: SwimWorkout

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: workout.type.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(workout.type.hue)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(workout.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    Pill(text: "\(Int(workout.totalDistanceMeters)) m", color: Theme.accent)
                    Pill(text: workout.type.label, color: workout.type.hue)
                }
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Start \(workout.name), \(Int(workout.totalDistanceMeters)) meters")
    }
}
