import SwiftUI
import SwiftData
import UIKit

/// Full-screen workout player: log sets, auto rest timer, finish summary.
struct RunnerView: View {
    @Bindable var runner: WorkoutRunner

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("keepAwake") private var keepAwake = true

    @State private var confirmDiscard = false
    @State private var confirmFinish = false
    @State private var summary: WorkoutSession?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 14) {
                        header
                        ForEach(runner.exercises.indices, id: \.self) { i in
                            ExerciseRunCard(runner: runner, exerciseIndex: i, unit: unit)
                        }
                        TextField("Session notes", text: $runner.note, axis: .vertical)
                            .lineLimit(2...4)
                            .glassCard()
                        Button {
                            confirmFinish = true
                        } label: {
                            Label("Finish workout", systemImage: "checkmark")
                        }
                        .buttonStyle(InkButtonStyle())
                        .disabled(runner.doneSets == 0)
                        Color.clear.frame(height: 70)
                    }
                    .padding(16)
                }
                restBar
            }
            .navigationTitle(runner.routineName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        confirmDiscard = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Discard workout")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        Text(Duration.mmss(Int(ctx.date.timeIntervalSince(runner.startedAt))))
                            .font(Brand.mono(15, weight: .medium))
                            .foregroundStyle(Brand.text2)
                            .accessibilityLabel("Elapsed time")
                    }
                }
            }
            .alert("Discard this workout?", isPresented: $confirmDiscard) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep training", role: .cancel) {}
            } message: {
                Text("Nothing will be saved.")
            }
            .alert("Finish workout?", isPresented: $confirmFinish) {
                Button("Finish") {
                    if let s = runner.finish(into: context) {
                        Haptics.success()
                        withAnimation(reduceMotion ? nil : Brand.ease()) { summary = s }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(runner.doneSets < runner.totalSets
                     ? "You've logged \(runner.doneSets) of \(runner.totalSets) sets. Unfinished sets are saved as skipped."
                     : "All sets logged. Nice work.")
            }
            .overlay {
                if let s = summary {
                    FinishSummaryView(session: s, unit: unit) { dismiss() }
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear { UIApplication.shared.isIdleTimerDisabled = keepAwake }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Eyebrow(text: "In session")
                Spacer()
                Text("\(runner.doneSets)/\(runner.totalSets) sets")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text2)
            }
            ProgressView(value: runner.progress)
                .tint(Brand.live)
                .accessibilityLabel("Workout progress")
                .accessibilityValue("\(runner.doneSets) of \(runner.totalSets) sets done")
        }
        .glassCard()
    }

    @ViewBuilder
    private var restBar: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
            if let remaining = runner.restRemaining(at: ctx.date) {
                HStack(spacing: 14) {
                    StatusDot()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Resting")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                        Text(Duration.mmss(remaining))
                            .font(Brand.mono(22, weight: .semibold))
                            .foregroundStyle(Brand.text)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    Button("+15s") { runner.extendRest(by: 15); Haptics.tap() }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Add 15 seconds of rest")
                    Button("Skip") { runner.skipRest(); Haptics.tap() }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.text)
                        .accessibilityLabel("Skip rest")
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.55), lineWidth: 1))
                .shadow(color: Brand.cardShadow, radius: 14, x: 0, y: 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
    }
}

private struct ExerciseRunCard: View {
    @Bindable var runner: WorkoutRunner
    let exerciseIndex: Int
    let unit: WeightUnit

    var body: some View {
        if runner.exercises.indices.contains(exerciseIndex) {
            let ex = runner.exercises[exerciseIndex]
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: ex.muscle.symbol)
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                    Text(ex.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Spacer()
                    if ex.supersetGroup > 0 {
                        Text("SS\(ex.supersetGroup)")
                            .font(Brand.mono(11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial, in: Capsule())
                            .accessibilityLabel("Superset group \(ex.supersetGroup)")
                    }
                }
                Text(ex.suggestionReason)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)

                ForEach(ex.sets.indices, id: \.self) { si in
                    SetRow(runner: runner, exerciseIndex: exerciseIndex, setIndex: si, unit: unit)
                }

                HStack {
                    Button {
                        runner.addSet(exercise: exerciseIndex)
                        Haptics.tap()
                    } label: {
                        Label("Add set", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                    }
                    Spacer()
                    if ex.sets.count > 1 {
                        Button(role: .destructive) {
                            runner.removeSet(exercise: exerciseIndex)
                            Haptics.tap()
                        } label: {
                            Label("Remove set", systemImage: "minus")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
                .buttonStyle(.borderless)
            }
            .glassCard()
        }
    }
}

private struct SetRow: View {
    @Bindable var runner: WorkoutRunner
    let exerciseIndex: Int
    let setIndex: Int
    let unit: WeightUnit

    var body: some View {
        if runner.exercises.indices.contains(exerciseIndex),
           runner.exercises[exerciseIndex].sets.indices.contains(setIndex) {
            let set = runner.exercises[exerciseIndex].sets[setIndex]
            HStack(spacing: 10) {
                Text("\(setIndex + 1)")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text3)
                    .frame(width: 18)
                    .accessibilityLabel("Set \(setIndex + 1)")

                // Weight
                HStack(spacing: 6) {
                    adjustButton("minus", "Decrease weight") { change(weightBy: -unit.step) }
                    Text(unit.format(kg: set.weightKg))
                        .font(Brand.mono(15, weight: .medium))
                        .foregroundStyle(Brand.text)
                        .frame(minWidth: 72)
                        .accessibilityLabel("Weight \(unit.format(kg: set.weightKg))")
                    adjustButton("plus", "Increase weight") { change(weightBy: unit.step) }
                }

                Spacer()

                // Reps
                HStack(spacing: 6) {
                    adjustButton("minus", "Decrease reps") { change(repsBy: -1) }
                    Text("\(set.reps)")
                        .font(Brand.mono(15, weight: .medium))
                        .foregroundStyle(Brand.text)
                        .frame(minWidth: 28)
                        .accessibilityLabel("\(set.reps) reps")
                    adjustButton("plus", "Increase reps") { change(repsBy: 1) }
                }

                Button {
                    runner.toggleSet(exercise: exerciseIndex, set: setIndex)
                    if runner.exercises[exerciseIndex].sets[setIndex].done {
                        Haptics.success()
                    } else {
                        Haptics.tap()
                    }
                } label: {
                    Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(set.done ? Brand.live : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(set.done ? "Set done" : "Mark set done")
            }
            .padding(.vertical, 2)
            .opacity(set.done ? 0.75 : 1)
        }
    }

    private func adjustButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption.weight(.bold))
                .frame(width: 26, height: 26)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func change(weightBy delta: Double = 0, repsBy repDelta: Int = 0) {
        guard runner.exercises.indices.contains(exerciseIndex),
              runner.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        if delta != 0 {
            let kg = runner.exercises[exerciseIndex].sets[setIndex].weightKg + unit.toKg(delta)
            runner.exercises[exerciseIndex].sets[setIndex].weightKg = max(0, kg)
        }
        if repDelta != 0 {
            let r = runner.exercises[exerciseIndex].sets[setIndex].reps + repDelta
            runner.exercises[exerciseIndex].sets[setIndex].reps = min(99, max(0, r))
        }
    }
}

private struct FinishSummaryView: View {
    let session: WorkoutSession
    let unit: WeightUnit
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 20) {
                Spacer()
                StatusDot()
                    .scaleEffect(2)
                Text("Workout saved")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Brand.text)
                VStack(spacing: 12) {
                    summaryRow("Duration", Duration.friendly(session.durationSeconds))
                    summaryRow("Sets completed", "\(session.doneSetCount)")
                    summaryRow("Volume moved", unit.format(kg: session.tonnageKg))
                }
                .glassCard()
                .padding(.horizontal, 24)
                Spacer()
                Button("Done") { onDone() }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(Brand.mono(16, weight: .semibold))
                .foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
    }
}
