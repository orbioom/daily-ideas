import SwiftUI
import SwiftData

/// Shows a workout's sets, totals, and a Start button. Custom workouts can be edited.
struct WorkoutDetailView: View {
    @Bindable var workout: SwimWorkout

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PrefKey.poolLengthRaw) private var poolLengthRaw = PoolLength.scm25.rawValue

    @State private var showEditor = false
    @State private var activeRunner: SwimRunner?

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }
    private var fmt: UnitFormatter { UnitFormatter(unit: unit) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if !workout.notes.isEmpty {
                        SectionCard(title: "Coach notes", symbol: "text.quote") {
                            Text(workout.notes)
                                .font(.callout)
                                .foregroundStyle(Theme.inkSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    setsList
                    PrimaryButton(title: "Start this workout", systemImage: "play.fill") {
                        Haptics.success(hapticsEnabled)
                        let reps = SwimRunner.reps(from: workout)
                        guard !reps.isEmpty else { return }
                        activeRunner = SwimRunner(reps: reps,
                                                  poolLengthMeters: workout.poolLengthMeters,
                                                  workoutName: workout.name,
                                                  isFreeSwim: false)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !workout.isBuiltIn {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showEditor = true }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            WorkoutBuilderView(existing: workout)
        }
        .fullScreenCover(item: $activeRunner) { runner in
            SwimRunnerView(runner: runner)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: workout.type.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.type.label)
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(fmt.distance(workout.totalDistanceMeters))
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            HStack(spacing: 18) {
                detail("Sets", "\(workout.orderedSets.count)")
                detail("Est. time", UnitFormatter.clock(Double(WorkoutMath.estimatedDuration(of: workout.orderedSets))))
                detail("Pool", "\(Int(workout.poolLengthMeters)) m")
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.waterGradient))
    }

    private func detail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .accessibilityElement(children: .combine)
    }

    private var setsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sets")
                .font(Theme.rounded(18, .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(workout.orderedSets.enumerated()), id: \.element.id) { index, set in
                SetRow(index: index + 1, set: set, unit: unit)
            }
        }
    }
}

/// One read-only set row in workout detail.
struct SetRow: View {
    let index: Int
    let set: SwimSet
    let unit: DistanceUnit

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 5) {
                Text("\(set.repeats) × \(Int(unit.value(fromMeters: set.distancePerRepMeters))) \(unit.shortUnit) \(set.stroke.label)")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    StrokeBadge(stroke: set.stroke)
                    Pill(text: set.effort.label, color: set.effort.hue, systemImage: set.effort.symbol)
                    if set.sendOffSeconds > 0 {
                        Pill(text: "@ \(UnitFormatter.clock(Double(set.sendOffSeconds)))", color: Theme.accentDeep)
                    } else if set.restSeconds > 0 {
                        Pill(text: "r\(set.restSeconds)s", color: Theme.good)
                    }
                }
                if !set.note.isEmpty {
                    Text(set.note)
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .combine)
    }
}
