import SwiftUI
import SwiftData

struct SessionPlayerView: View {
    let dog: Dog
    let trickId: String

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \CustomTrick.createdAt) private var customTricks: [CustomTrick]

    @State private var engine: SessionEngine
    @State private var clicker = Clicker()
    @State private var phase: Phase = .running
    @State private var clickPulse = false
    @State private var lastForegroundAt = Date()

    // Finish form
    @State private var rating = 4
    @State private var note = ""

    enum Phase { case running, finishing, saved }

    init(dog: Dog, trickId: String) {
        self.dog = dog
        self.trickId = trickId
        _engine = State(initialValue: SessionEngine(trickId: trickId))
    }

    private var trick: Trick { TrickResolver.resolve(trickId, custom: customTricks) }

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()
            Color.black.opacity(0.08).ignoresSafeArea()

            switch phase {
            case .running:
                runningView
            case .finishing:
                finishingView
            case .saved:
                savedView
            }
        }
        .onAppear { engine.start() }
        .onChange(of: scenePhase) { _, newPhase in
            // The timer is anchored to wall-clock dates, so elapsed time stays correct
            // across backgrounding. Returning to foreground simply lets TimelineView
            // resume ticking; refreshing the displayed time here keeps it snappy.
            if newPhase == .active {
                lastForegroundAt = Date()
            }
        }
        .onDisappear { clicker.stop() }
    }

    // MARK: - Running

    private var runningView: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            trickBadge
            Spacer().frame(height: 24)
            timerDisplay
            Spacer().frame(height: 28)
            repCounter
            Spacer()
            clickerButton
            Spacer().frame(height: 18)
            controls
            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 24)
    }

    private var topBar: some View {
        HStack {
            Button {
                cancelSession()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(11)
                    .background(Circle().fill(.white.opacity(0.18)))
            }
            .accessibilityLabel("Cancel session")
            Spacer()
            Text("Training \(dog.name)")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, 12)
    }

    private var trickBadge: some View {
        VStack(spacing: 10) {
            Image(systemName: trick.icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 78, height: 78)
                .background(Circle().fill(.white.opacity(0.18)))
                .accessibilityHidden(true)
            Text(trick.name)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(.white)
        }
    }

    private var timerDisplay: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let elapsed = engine.elapsedSeconds(at: context.date)
            VStack(spacing: 4) {
                Text(Format.clock(elapsed))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(engine.isPaused ? "Paused" : "Elapsed")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Elapsed time \(Format.clock(elapsed))\(engine.isPaused ? ", paused" : "")")
        }
    }

    private var repCounter: some View {
        HStack(spacing: 28) {
            repButton(system: "minus") { engine.removeRep(); Haptics.selection(enabled: settings.hapticsEnabled) }
            VStack(spacing: 2) {
                Text("\(engine.reps)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("reps")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(minWidth: 96)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(engine.reps) reps")
            repButton(system: "plus") { engine.addRep(); Haptics.impact(.light, enabled: settings.hapticsEnabled) }
        }
    }

    private func repButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(.white.opacity(0.2)))
        }
        .accessibilityLabel(system == "plus" ? "Add a rep" : "Remove a rep")
    }

    private var clickerButton: some View {
        Button {
            triggerClick()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 40, weight: .bold))
                Text("CLICK")
                    .font(Theme.rounded(16, .heavy))
                    .tracking(2)
            }
            .foregroundStyle(Theme.accentDeep)
            .frame(width: 168, height: 168)
            .background(Circle().fill(.white))
            .overlay(
                Circle().stroke(.white.opacity(0.6), lineWidth: clickPulse ? 14 : 0)
            )
            .scaleEffect(clickPulse && !reduceMotion ? 1.06 : 1)
            .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
        }
        .accessibilityLabel("Clicker. Marks the moment your dog does it right.")
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                if engine.isPaused { engine.resume() } else { engine.pause() }
                Haptics.impact(.medium, enabled: settings.hapticsEnabled)
            } label: {
                Label(engine.isPaused ? "Resume" : "Pause",
                      systemImage: engine.isPaused ? "play.fill" : "pause.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.2)))
            }
            Button {
                engine.pause()
                withAnimation(reduceMotion ? nil : .easeInOut) { phase = .finishing }
            } label: {
                Label("Finish", systemImage: "checkmark")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.accentDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            }
        }
    }

    private func triggerClick() {
        if settings.clickerSoundEnabled {
            clicker.click()
        }
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { clickPulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.25)) { clickPulse = false }
        }
    }

    // MARK: - Finishing

    private var finishingView: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text("Great work!")
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(.white)
                    Text("Log this \(trick.name) session")
                        .font(Theme.rounded(15))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 40)

                summaryRow

                ratingPicker

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        TextEditor(text: $note)
                            .font(Theme.rounded(15))
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceAlt))
                    }
                }

                VStack(spacing: 10) {
                    Button { saveSession() } label: {
                        Text("Save session")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Back to session") {
                        withAnimation(reduceMotion ? nil : .easeInOut) { phase = .running }
                        engine.resume()
                    }
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            summaryStat(value: Format.clock(engine.elapsedSeconds()), label: "Time")
            summaryStat(value: "\(engine.reps)", label: "Reps")
        }
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.18)))
    }

    private var ratingPicker: some View {
        Card {
            VStack(spacing: 10) {
                Text("How did it go?")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            rating = star
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(star <= rating ? Theme.warn : Theme.hairline)
                        }
                        .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                        .accessibilityAddTraits(star == rating ? [.isSelected] : [])
                    }
                }
            }
        }
    }

    // MARK: - Saved

    private var savedView: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text("Session saved!")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(.white)
            Text("\(dog.name)'s progress on \(trick.name) is updated.")
                .font(Theme.rounded(15))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session saved. Progress updated.")
    }

    // MARK: - Actions

    private func cancelSession() {
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func saveSession() {
        let duration = engine.finalDurationSeconds()
        let session = TrainingSession(
            dog: dog,
            trickId: trickId,
            date: Date(),
            durationSec: duration,
            reps: engine.reps,
            successRating: rating,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(session)

        // Update / advance progress.
        let row = DogManager.progressRow(for: dog, trickId: trickId, context: context)
        row.sessionCount += 1
        row.lastPracticed = Date()
        row.updatedAt = Date()
        // Nudge status forward sensibly: never demote, advance on good sessions.
        if row.status == .notStarted {
            row.status = .learning
        } else if row.status == .learning && row.sessionCount >= 3 && rating >= 4 {
            row.status = .practicing
        } else if row.status == .practicing && row.sessionCount >= 5 && rating == 5 {
            row.status = .mastered
        }

        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)

        withAnimation(reduceMotion ? nil : .spring(response: 0.4)) { phase = .saved }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            dismiss()
        }
    }
}
