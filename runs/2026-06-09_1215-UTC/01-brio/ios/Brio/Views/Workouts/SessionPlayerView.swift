import SwiftUI
import SwiftData
import UIKit

/// Full-screen guided player. A TimelineView(.animation) drives `engine.tick()`
/// so timed phases count down and auto-advance; rep-based steps wait for the
/// "Done" button. Keeps the screen awake while active (per setting) and resets
/// on dismiss. On finish, collects a quick feeling rating + note and logs a
/// `WorkoutSession`.
struct SessionPlayerView: View {
    let workout: Workout
    let countInSeconds: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("brio.keepAwake") private var keepAwake = true
    @AppStorage("brio.haptics") private var haptics = true

    @State private var engine = PlayerEngine()
    @State private var feeling = 0
    @State private var note = ""
    @State private var breathe = false
    @State private var didSave = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1B1E2A), Color(hex: 0x0E0F15)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if engine.isFinished {
                reflection
            } else {
                active
            }
        }
        .onAppear {
            engine.hapticsOnCue = haptics
            UIApplication.shared.isIdleTimerDisabled = keepAwake
            engine.start(workout, countInSeconds: countInSeconds)
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                    breathe = true
                }
            }
        }
        .onDisappear {
            engine.reset()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .statusBarHidden(true)
    }

    // MARK: - Active session

    private var active: some View {
        // The engine drives its own 0.2s timer, refreshing this view via
        // @Observable; the progress ring animates the rest of the way.
        let step = engine.currentStep
        return VStack(spacing: 0) {
            topBar(step: step)

            ProgressView(value: engine.progress)
                .tint(Brand.magic)
                .padding(.horizontal, 24)
                .padding(.top, 6)
                .accessibilityLabel("Session progress")
                .accessibilityValue("\(Int(engine.progress * 100)) percent")

            Spacer()

            phaseDisplay(step: step)

            Spacer()

            controls(step: step)
        }
    }

    private func topBar(step: WorkoutStep?) -> some View {
        HStack {
            Button {
                Haptics.tap()
                engine.finishEarly()
            } label: {
                Text("End")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            .accessibilityLabel("End workout early")
            Spacer()
            if let step {
                Text("Round \(min(step.roundIndex + 1, engine.totalRounds)) of \(engine.totalRounds)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    @ViewBuilder
    private func phaseDisplay(step: WorkoutStep?) -> some View {
        if let step {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(tint(for: step).opacity(0.08))
                        .frame(width: 300, height: 300)
                        .scaleEffect(breathe && step.isTimed ? 1.05 : 0.95)
                    if step.isTimed {
                        ProgressRing(progress: engine.phaseProgress, lineWidth: 8, tint: tint(for: step))
                            .frame(width: 280, height: 280)
                    } else {
                        Circle()
                            .stroke(tint(for: step).opacity(0.25), lineWidth: 8)
                            .frame(width: 280, height: 280)
                    }
                    VStack(spacing: 8) {
                        Image(systemName: step.symbol)
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(tint(for: step))
                            .accessibilityHidden(true)
                        if step.isTimed {
                            Text(Format.clock(engine.phaseRemaining))
                                .font(Brand.mono(54, weight: .light))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                        } else {
                            Text(step.subtitle)
                                .font(Brand.mono(30, weight: .light))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityPhaseLabel(step))

                VStack(spacing: 6) {
                    Text(label(for: step))
                        .font(Brand.mono(12, weight: .medium))
                        .tracking(1.6)
                        .foregroundStyle(tint(for: step))
                    Text(step.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if step.isTimed {
                        Text(step.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    if let next = engine.nextStep, next.kind != .done {
                        Text("Next: \(next.title)")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func controls(step: WorkoutStep?) -> some View {
        let isManual = step?.isTimed == false && step?.kind == .exercise
        VStack(spacing: 16) {
            if isManual {
                Button {
                    Haptics.success()
                    engine.advance()
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 40)
            }

            HStack(spacing: 40) {
                Button {
                    engine.skip()
                } label: {
                    controlIcon("forward.fill", label: "Skip")
                }
                .accessibilityLabel("Skip this step")

                if step?.isTimed == true {
                    Button {
                        Haptics.tap()
                        engine.pauseToggle()
                    } label: {
                        Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(.white.opacity(0.14), in: Circle())
                    }
                    .accessibilityLabel(engine.isPaused ? "Resume" : "Pause")
                }
            }
            .padding(.bottom, 40)
        }
    }

    private func controlIcon(_ name: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: name)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 54, height: 54)
                .background(.white.opacity(0.10), in: Circle())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Reflection

    private var reflection: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 40)
                Image(systemName: engine.finishedFully ? "checkmark.circle.fill" : "flag.checkered")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                VStack(spacing: 6) {
                    Text(engine.finishedFully ? "Workout complete" : "Workout ended")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(Format.duration(engine.elapsedSeconds)) · \(engine.roundsCompleted) of \(engine.totalRounds) rounds")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 10) {
                    Text("How did that feel?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                    FeelingPicker(feeling: $feeling)
                }
                .padding(.top, 4)

                TextField("A word about this session (optional)", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(12)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)

                Spacer(minLength: 20)

                Button("Save & close") { save() }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 24)
                    .disabled(didSave)

                Button("Discard") {
                    Haptics.tap()
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Helpers

    private func save() {
        guard !didSave else { return }
        didSave = true
        let session = engine.buildSession()
        session.feeling = feeling
        session.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        context.insert(session)
        do {
            try context.save()
            Haptics.success()
        } catch {
            // Recoverable: keep the sheet open so the user can retry.
            didSave = false
            return
        }
        dismiss()
    }

    private func tint(for step: WorkoutStep) -> Color {
        switch step.kind {
        case .countIn: return Brand.warn
        case .exercise: return Brand.magic
        case .restExercise, .restRound: return Brand.info
        case .done: return Brand.live
        }
    }

    private func label(for step: WorkoutStep) -> String {
        switch step.kind {
        case .countIn: return "GET READY"
        case .exercise: return "EXERCISE"
        case .restExercise: return "REST"
        case .restRound: return "ROUND REST"
        case .done: return "DONE"
        }
    }

    private func accessibilityPhaseLabel(_ step: WorkoutStep) -> String {
        if step.isTimed {
            return "\(step.title), \(Format.clock(engine.phaseRemaining)) remaining"
        }
        return "\(step.title), \(step.subtitle)"
    }
}
