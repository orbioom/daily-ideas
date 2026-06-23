import SwiftUI
import SwiftData

/// Full-screen guided breathing player: pre-mood → live pacer → post-mood/summary.
struct SessionPlayerView: View {
    let pattern: BreathPattern
    let minutes: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsRows: [AppSettings]

    private enum Stage { case preMood, breathing, summary }

    @State private var stage: Stage = .preMood
    @State private var moodBefore = 3
    @State private var moodAfter = 3
    @State private var engine: BreathEngine?
    @State private var note = ""
    @State private var savedSession = false

    private var settings: AppSettings? { settingsRows.first }
    private var accent: Color { pattern.style.accent }

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()
            switch stage {
            case .preMood: preMoodView
            case .breathing: breathingView
            case .summary: summaryView
            }
        }
        .preferredColorScheme(nil)
        .onChange(of: scenePhase) { _, phase in
            // Pause automatically if the user leaves mid-session.
            if phase != .active, engine?.state == .running {
                engine?.pause()
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(colors: [Theme.bgPrimary, accent.opacity(0.18), Theme.bgPrimary],
                       startPoint: .top, endPoint: .bottom)
    }

    // MARK: Pre-mood check-in

    private var preMoodView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            closeButton
            Spacer()
            Image(systemName: pattern.style.systemImage)
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(accent)
                .accessibilityHidden(true)
            Text(pattern.name).font(.title.bold()).foregroundStyle(Theme.textPrimary)
            Text("How do you feel right now?")
                .font(.headline)
                .foregroundStyle(Theme.textSecondary)
            MoodPicker(selection: $moodBefore, reduceMotion: reduceMotion)
                .padding(.horizontal, Theme.Spacing.md)
            Spacer()
            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    startBreathing()
                } label: {
                    Label("Begin", systemImage: "play.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                Button("Skip check-in") {
                    moodBefore = 0
                    startBreathing()
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    // MARK: Breathing

    @ViewBuilder
    private var breathingView: some View {
        if let engine {
            BreathingSessionView(engine: engine,
                                 accent: accent,
                                 reduceMotion: reduceMotion,
                                 onClose: { endEarly(engine) },
                                 onFinish: { goToSummary() })
        } else {
            LoadingView(message: "Preparing your session…")
        }
    }

    // MARK: Summary + post-mood

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                closeButton
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.good)
                    .accessibilityHidden(true)
                Text("Session complete").font(.title.bold()).foregroundStyle(Theme.textPrimary)
                if let engine {
                    Text("\(formattedDuration(engine.elapsed)) · \(engine.unitsCompleted) \(pattern.isRounds ? "rounds" : "cycles")")
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: Theme.Spacing.sm) {
                    Text("How do you feel now?")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    MoodPicker(selection: $moodAfter, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, Theme.Spacing.md)

                if moodBefore > 0 {
                    let delta = moodAfter - moodBefore
                    Text(delta > 0 ? "That's a lift of +\(delta). Nicely done." :
                            (delta == 0 ? "Steady and centered." : "Be gentle with yourself today."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Note (optional)").font(.caption).foregroundStyle(Theme.textSecondary)
                    TextField("A word about this session…", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                }
                .padding(.horizontal, Theme.Spacing.md)

                Button {
                    saveAndDismiss()
                } label: {
                    Label("Save & Finish", systemImage: "checkmark")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                Haptics.shared.tap()
                if stage == .summary && !savedSession {
                    saveAndDismiss()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityLabel("Close session")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: Flow

    private func startBreathing() {
        let target = Double(minutes * 60)
        let countdown = settings?.preparationCountdown ?? true
        let e = BreathEngine(pattern: pattern, targetSeconds: target, countdownEnabled: countdown)
        e.reset()
        e.onComplete = { goToSummary() }
        engine = e
        stage = .breathing
        UIApplication.shared.isIdleTimerDisabled = (settings?.keepScreenAwake ?? true)
        e.start()
    }

    private func goToSummary() {
        moodAfter = max(moodBefore, 3)
        UIApplication.shared.isIdleTimerDisabled = false
        withAnimation { stage = .summary }
    }

    private func endEarly(_ engine: BreathEngine) {
        engine.pause()
        UIApplication.shared.isIdleTimerDisabled = false
        // If they breathed at least a little, let them log it; otherwise just leave.
        if engine.elapsed >= 10 {
            goToSummary()
        } else {
            dismiss()
        }
    }

    private func saveAndDismiss() {
        guard !savedSession else { dismiss(); return }
        savedSession = true
        let elapsed = engine?.elapsed ?? 0
        let units = engine?.unitsCompleted ?? 0
        let finished = (engine?.state == .finished)
        let session = BreathSession(
            durationSeconds: max(0, elapsed),
            patternID: pattern.id,
            patternName: pattern.name,
            styleRaw: pattern.style.rawValue,
            cyclesCompleted: units,
            finished: finished,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(session)
        try? context.save()
        Haptics.shared.success()
        dismiss()
    }

    private func formattedDuration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    SessionPlayerView(pattern: PatternLibrary.all[0], minutes: 3)
        .previewModelContainer()
}
