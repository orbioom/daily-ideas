import SwiftUI
import SwiftData

@Observable
final class PlayerEngine {
    let session: YogaSession
    private(set) var currentStepIndex = 0
    private(set) var elapsed: Double = 0
    private(set) var isPaused = false
    private(set) var isComplete = false
    var moodBefore: Int = 3

    private var timer: Timer?

    init(session: YogaSession) {
        self.session = session
    }

    var currentStep: SessionStep? {
        session.steps.indices.contains(currentStepIndex) ? session.steps[currentStepIndex] : nil
    }

    var nextStep: SessionStep? {
        let next = currentStepIndex + 1
        return session.steps.indices.contains(next) ? session.steps[next] : nil
    }

    var stepProgress: Double {
        guard let step = currentStep, step.durationSeconds > 0 else { return 0 }
        return min(1, elapsed / Double(step.durationSeconds))
    }

    var overallProgress: Double {
        guard !session.steps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(session.steps.count)
    }

    func start() {
        isPaused = false
        scheduleTimer()
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused { timer?.invalidate() } else { scheduleTimer() }
    }

    func skipToNext() {
        advance()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let step = currentStep else { return }
        elapsed += 0.1
        if elapsed >= Double(step.durationSeconds) {
            advance()
        }
    }

    private func advance() {
        elapsed = 0
        currentStepIndex += 1
        if currentStepIndex >= session.steps.count {
            isComplete = true
            timer?.invalidate()
        }
    }

    func stop() {
        timer?.invalidate()
    }
}

struct SessionPlayerView: View {
    let session: YogaSession
    @State private var engine: PlayerEngine
    @State private var moodAfter = 3
    @State private var notes = ""
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hapticsEnabled") private var haptics = true

    init(session: YogaSession) {
        self.session = session
        self._engine = State(initialValue: PlayerEngine(session: session))
    }

    var body: some View {
        ZStack {
            FlowTheme.gradient(for: session)
                .ignoresSafeArea()

            if engine.isComplete {
                completionView
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            } else {
                playerContent
            }
        }
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: engine.currentStepIndex)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: engine.isComplete)
    }

    @ViewBuilder
    private var playerContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button { engine.stop(); dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                        .accessibilityLabel("End session")
                }
                Spacer()
                Text("\(currentStepLabel)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            ProgressView(value: engine.overallProgress)
                .tint(.white)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Spacer()

            if let step = engine.currentStep {
                VStack(spacing: 24) {
                    Text(step.pose.emoji)
                        .font(.system(size: 96))
                        .accessibilityHidden(true)

                    Text(step.pose.name + sideLabel(step.side))
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(step.pose.sanskrit)
                        .font(.subheadline.italic())
                        .foregroundStyle(.white.opacity(0.7))

                    Text(step.cue)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 6)
                            .frame(width: 90, height: 90)
                        Circle()
                            .trim(from: 0, to: engine.stepProgress)
                            .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                            .animation(reduceMotion ? .none : .linear(duration: 0.1), value: engine.stepProgress)
                        Text("\(max(0, step.durationSeconds - Int(engine.elapsed)))s")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Time remaining: \(max(0, step.durationSeconds - Int(engine.elapsed))) seconds")
                }
            }

            Spacer()

            if let next = engine.nextStep {
                Text("Next: \(next.pose.name)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 8)
            }

            HStack(spacing: 40) {
                Button { engine.togglePause() } label: {
                    Image(systemName: engine.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                        .accessibilityLabel(engine.isPaused ? "Resume" : "Pause")
                }

                Button { engine.skipToNext() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.7))
                        .accessibilityLabel("Skip to next pose")
                }
            }
            .padding(.bottom, 60)
        }
    }

    @ViewBuilder
    private var completionView: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 60)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)

                Text("Session Complete!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                Text("\(session.name) · \(session.totalDurationMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                VStack(spacing: 16) {
                    Text("How do you feel now?")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: 16) {
                        ForEach(1...5, id: \.self) { mood in
                            Button {
                                moodAfter = mood
                            } label: {
                                Text(FlowTheme.moodEmoji(mood))
                                    .font(.system(size: 36))
                                    .opacity(moodAfter == mood ? 1.0 : 0.5)
                                    .scaleEffect(moodAfter == mood ? 1.1 : 1.0)
                                    .animation(reduceMotion ? .none : .spring(response: 0.2), value: moodAfter)
                            }
                            .accessibilityLabel("Mood \(mood)")
                            .accessibilityAddTraits(moodAfter == mood ? [.isSelected] : [])
                        }
                    }

                    TextField("Add a note (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .padding()
                        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .accessibilityLabel("Session notes")
                }
                .padding(.horizontal, 32)

                Button {
                    saveAndDismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 32)
                }
                .accessibilityHint("Save session and return home")

                Spacer().frame(height: 40)
            }
        }
    }

    private var currentStepLabel: String {
        "\(engine.currentStepIndex + 1) / \(engine.session.steps.count)"
    }

    private func sideLabel(_ side: SessionStep.StepSide) -> String {
        switch side {
        case .left: return " (Left)"
        case .right: return " (Right)"
        case .both: return ""
        }
    }

    private func saveAndDismiss() {
        let record = CompletedSession(
            sessionId: session.id,
            sessionName: session.name,
            durationMinutes: session.totalDurationMinutes,
            moodBefore: engine.moodBefore,
            moodAfter: moodAfter,
            notes: notes
        )
        ctx.insert(record)
        dismiss()
    }
}
