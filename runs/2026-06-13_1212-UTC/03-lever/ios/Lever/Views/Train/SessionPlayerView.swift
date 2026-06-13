import SwiftUI
import SwiftData
import UIKit

/// The full-screen guided session player: work each set, rest between, then a
/// summary that logs the workout and promotes the user if they earned it.
struct SessionPlayerView: View {
    let plan: SessionPlan
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("keepAwake") private var keepAwake = true

    @Query private var progressRecords: [ExerciseProgress]
    @Query(sort: \WorkoutLog.date, order: .reverse) private var allLogs: [WorkoutLog]

    @State private var vm: SessionPlayerViewModel
    @State private var didSave = false
    @State private var didAdvance = false

    init(plan: SessionPlan) {
        self.plan = plan
        _vm = State(initialValue: SessionPlayerViewModel(plan: plan))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch vm.phase {
            case .working: workingView
            case .resting: restingView
            case .done: summaryView
            }
        }
        .onAppear { if keepAwake { UIApplication.shared.isIdleTimerDisabled = true } }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: Working

    private var workingView: some View {
        VStack(spacing: 16) {
            header
            Spacer()
            Pill(text: vm.progressText)
            Text(vm.exercise.unit.verb + " target: \(vm.setTarget) \(vm.exercise.unit.short)")
                .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)

            if vm.unit == .reps {
                repCounter
            } else {
                holdTimer
            }

            Spacer()

            Button { vm.completeSet() } label: {
                Text(vm.setIndex < plan.totalSets - 1 ? "Done — start rest" : "Finish set")
                    .font(Theme.rounded(18, .bold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .disabled(vm.unit == .seconds && vm.holdRunning)
            .opacity(vm.unit == .seconds && vm.holdRunning ? 0.5 : 1)

            Button("End session") { vm.finish() }
                .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft).padding(.bottom, 16)
        }
    }

    private var repCounter: some View {
        VStack(spacing: 18) {
            Text("\(vm.currentValue)")
                .font(.system(size: 88, weight: .bold, design: .rounded))
                .monospacedDigit().foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .accessibilityLabel("\(vm.currentValue) reps")
            HStack(spacing: 22) {
                stepButton("minus", disabled: vm.currentValue <= 0) { vm.bump(-1) }
                stepButton("plus") { vm.bump(1) }
            }
        }
    }

    private func stepButton(_ symbol: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(disabled ? Theme.inkFaint : Theme.accent, in: Circle())
        }
        .disabled(disabled)
        .accessibilityLabel(symbol == "plus" ? "Add a rep" : "Remove a rep")
    }

    private var holdTimer: some View {
        VStack(spacing: 18) {
            Text(Fmt.clock(vm.currentValue))
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .monospacedDigit().foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .accessibilityLabel("\(vm.currentValue) seconds held")
            if vm.holdRunning {
                Button { vm.stopHold() } label: {
                    Label("Stop hold", systemImage: "stop.fill")
                        .font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                        .padding(.vertical, 14).padding(.horizontal, 28)
                        .background(Theme.bad, in: Capsule())
                }
            } else {
                Button { vm.startHold() } label: {
                    Label(vm.currentValue > 0 ? "Restart hold" : "Start hold", systemImage: "play.fill")
                        .font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                        .padding(.vertical, 14).padding(.horizontal, 28)
                        .background(Theme.accent, in: Capsule())
                }
            }
        }
    }

    // MARK: Resting

    private var restingView: some View {
        VStack(spacing: 18) {
            header
            Spacer()
            Image(systemName: "hourglass")
                .font(.system(size: 52)).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
                .scaleEffect(reduceMotion ? 1 : (vm.restRemaining % 2 == 0 ? 1.0 : 0.92))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: vm.restRemaining)
            Text("Rest").font(Theme.rounded(20, .bold)).foregroundStyle(Theme.inkSoft)
            Text(Fmt.clock(vm.restRemaining))
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .monospacedDigit().foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .accessibilityLabel("\(vm.restRemaining) seconds of rest remaining")
            Text("Next: set \(min(vm.setIndex + 2, plan.totalSets)) of \(plan.totalSets)")
                .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Button { vm.skipRest() } label: {
                Text("Skip rest").font(Theme.rounded(18, .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 16).padding(.bottom, 24)
        }
    }

    // MARK: Summary

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: didAdvance ? "arrow.up.circle.fill" : "checkmark.seal.fill")
                    .font(.system(size: 64)).foregroundStyle(didAdvance ? Theme.good : Theme.accent)
                    .padding(.top, 24).accessibilityHidden(true)
                Text(didAdvance ? "Level up!" : "Session complete")
                    .font(Theme.rounded(28, .bold)).foregroundStyle(Theme.ink)
                Text(vm.exercise.name + " · " + plan.level.name)
                    .font(Theme.rounded(16, .medium)).foregroundStyle(Theme.inkSoft)

                if didAdvance, let next = vm.exercise.level(at: plan.level.index + 1) {
                    Card {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("You earned the next rung", systemImage: "trophy.fill")
                                .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.good)
                            Text("Promoted to \(next.name).")
                                .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.ink)
                            Text(targetSummary(vm.exercise, next))
                                .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your sets").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                        let target = plan.level.target
                        ForEach(Array(vm.results.enumerated()), id: \.offset) { idx, value in
                            HStack {
                                Text("Set \(idx + 1)").font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.inkSoft)
                                Spacer()
                                Text("\(value) \(vm.exercise.unit.short)")
                                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                                Image(systemName: value >= target ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(value >= target ? Theme.good : Theme.inkFaint)
                            }
                            if idx < vm.results.count - 1 { Divider().background(Theme.hairline) }
                        }
                        if vm.results.isEmpty {
                            Text("No sets logged — ended early.")
                                .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 16) {
                    StatTile(value: "\(vm.results.reduce(0, +))",
                             label: "Total \(vm.exercise.unit.short)")
                    StatTile(value: vm.hitTarget ? "Yes" : "No",
                             label: "Hit target", accent: vm.hitTarget ? Theme.good : Theme.inkSoft)
                }
                .padding(.horizontal, 16)

                Button { dismiss() } label: {
                    Text("Done").font(Theme.rounded(18, .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16).padding(.bottom, 28)
            }
        }
        .onAppear(perform: persistIfNeeded)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ExerciseGlyph(exercise: vm.exercise)
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.exercise.name).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                Text(plan.level.name).font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26)).foregroundStyle(Theme.inkFaint)
            }
            .accessibilityLabel("Close session")
        }
        .padding(.horizontal, 16).padding(.top, 12)
    }

    // MARK: Persistence + promotion

    private func persistIfNeeded() {
        guard !didSave else { return }
        didSave = true
        guard !vm.results.isEmpty else { return }

        let savedLog = vm.save(to: context)

        // Pull this exercise's recent logs (now including the one just saved).
        let exID = vm.exercise.id
        var recent = allLogs.filter { $0.exerciseID == exID }
        if !recent.contains(where: { $0 === savedLog }) { recent.append(savedLog) }

        let record = ProgressStore.progress(for: exID, in: progressRecords, context: context)

        // Only promote when training at (or above) the current level and the
        // engine confirms the last two sessions cleared the target.
        if plan.level.index >= record.currentLevel,
           ProgressionEngine.shouldAdvance(level: plan.level, recentLogs: recent),
           plan.level.index < vm.exercise.levels.count - 1 {
            record.currentLevel = plan.level.index + 1
            try? context.save()
            didAdvance = true
        }
    }
}
