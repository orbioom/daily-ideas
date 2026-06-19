import SwiftUI

struct BreakPlayerView: View {
    let schedule: UserSchedule
    let onComplete: (Bool) -> Void

    @State private var engine = BreakSessionEngine()
    @State private var showSuccessOverlay = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PoiseTheme.breakGradient
                .ignoresSafeArea()

            if showSuccessOverlay {
                successOverlay
            } else {
                mainContent
            }
        }
        .onAppear {
            let exercises = ExerciseLibrary.randomSession(
                categories: schedule.exerciseCategoriesArray,
                durationSeconds: schedule.breakDurationSeconds
            )
            engine.startSession(exercises: exercises)
        }
        .onChange(of: engine.isComplete) { _, complete in
            if complete {
                withAnimation(.spring(duration: 0.5)) {
                    showSuccessOverlay = true
                }
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    engine.stopSession()
                    onComplete(false)
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                        .padding(12)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }

                Spacer()

                Text("Break Time")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Pause/Resume
                Button {
                    if engine.isRunning {
                        engine.pause()
                    } else {
                        engine.resume()
                    }
                } label: {
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .padding(12)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            // Progress dots
            BreakProgressBar(current: engine.currentIndex, total: engine.totalExercises)
                .padding(.bottom, 24)

            // Phase indicator
            if engine.phase == .resting {
                restingView
            } else if let exercise = engine.currentExercise {
                exerciseContent(exercise: exercise)
            }

            Spacer()

            // Controls
            bottomControls
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
        }
    }

    private func exerciseContent(exercise: Exercise) -> some View {
        VStack(spacing: 24) {
            // Exercise number
            Text("\(engine.currentIndex + 1) of \(engine.totalExercises)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())

            // Icon
            Image(systemName: exercise.sfSymbol)
                .font(.system(size: 48))
                .foregroundColor(.white)
                .frame(width: 96, height: 96)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())

            // Exercise name
            Text(exercise.name)
                .font(.title.weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Instruction
            Text(exercise.instruction)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(4)

            // Countdown ring
            CountdownRingView(
                progress: engine.progressFraction,
                total: exercise.durationSeconds,
                remaining: engine.timeRemaining,
                ringColor: .white,
                size: 140
            )

            // Next up
            if let next = engine.nextExercise {
                HStack(spacing: 8) {
                    Text("Next:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(next.name)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    private var restingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.8))

            Text("Rest")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.white)

            Text("\(engine.restCountdown)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()

            if let next = engine.nextExercise {
                Text("Coming up: \(next.name)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 20) {
            // Skip
            Button {
                engine.skip()
            } label: {
                Label("Skip", systemImage: "forward.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }

            if engine.currentIndex == engine.totalExercises - 1 {
                // Done button on last exercise
                Button {
                    engine.stopSession()
                    onComplete(true)
                    withAnimation {
                        showSuccessOverlay = true
                    }
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .font(.headline)
                        .foregroundColor(PoiseTheme.sky)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var successOverlay: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 20)

            VStack(spacing: 8) {
                Text("Great job!")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.white)

                Text("Break completed")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))
            }

            VStack(spacing: 8) {
                Text("\(engine.totalExercises) exercise\(engine.totalExercises == 1 ? "" : "s") completed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Text("Your body thanks you.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 40)
            .multilineTextAlignment(.center)

            Spacer()

            Button {
                onComplete(true)
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(PoiseTheme.sky)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
    }
}
