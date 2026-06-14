import SwiftUI
import SwiftData

/// The playable drill: staff with one note, answer pad, live score, and end summary.
struct DrillPlayerView: View {
    let config: DrillConfig

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var engine: DrillEngine
    @State private var flash: Bool = false

    init(config: DrillConfig) {
        self.config = config
        _engine = State(initialValue: DrillEngine(config: config))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch engine.phase {
            case .idle:
                ProgressView().controlSize(.large)
            case .running:
                runningView
            case .finished:
                DrillSummaryView(engine: engine,
                                 onAgain: { engine.again(context: context, settings: settings) },
                                 onDone: { dismiss() })
            }
        }
        .onAppear {
            if engine.phase == .idle {
                engine.start(context: context, settings: settings)
            }
        }
        .onDisappear { engine.pause() }
    }

    // MARK: Running

    private var runningView: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)
            staffArea
            Spacer(minLength: 8)
            feedbackBar
            answerArea
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button {
                engine.pause()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.inkFaint)
            }
            .accessibilityLabel("End drill")

            Spacer()

            scoreCluster

            Spacer()

            progressRing
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var scoreCluster: some View {
        HStack(spacing: 16) {
            stat("\(engine.correct)/\(engine.total)", "Score")
            stat("\(engine.streak)", "Streak")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink).monospacedDigit()
            Text(label).font(Theme.rounded(10)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: 5)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: ringProgress)
            Text(ringLabel)
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .frame(width: 46, height: 46)
        .accessibilityLabel(ringAccessibility)
    }

    private var ringProgress: CGFloat {
        if config.mode == .timed {
            return CGFloat(engine.elapsedSec) / CGFloat(max(1, DrillConfig.timedDurationSec))
        }
        return CGFloat(engine.total) / CGFloat(max(1, engine.targetCount))
    }

    private var ringLabel: String {
        config.mode == .timed ? "\(engine.remainingSec)" : "\(engine.total)/\(engine.targetCount)"
    }

    private var ringAccessibility: String {
        config.mode == .timed
            ? "\(engine.remainingSec) seconds remaining"
            : "\(engine.total) of \(engine.targetCount) notes"
    }

    // MARK: Staff

    private var staffArea: some View {
        StaffView(clef: config.clef,
                  midi: engine.currentMIDI,
                  noteColor: noteColor,
                  accessibilityText: NoteDescription.describe(midi: engine.currentMIDI,
                                                              clef: config.clef,
                                                              useFlats: settings.useFlats))
            .frame(height: 220)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                    .padding(.horizontal, 12)
            )
            .opacity(flashOpacity)
    }

    private var noteColor: Color {
        switch engine.lastWasCorrect {
        case .some(true): return Theme.good
        case .some(false): return Theme.bad
        case .none: return Theme.staff
        }
    }

    private var flashOpacity: Double {
        guard !reduceMotion else { return 1 }
        return flash ? 0.65 : 1
    }

    // MARK: Feedback

    private var feedbackBar: some View {
        Group {
            if let wasCorrect = engine.lastWasCorrect {
                HStack(spacing: 8) {
                    Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(wasCorrect ? "Correct" : "That was \(engine.revealName ?? "—")")
                }
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(wasCorrect ? Theme.good : Theme.bad)
                .transition(reduceMotion ? .identity : .opacity)
            } else {
                Text("Name this note")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(height: 26)
        .padding(.bottom, 12)
    }

    // MARK: Answer pad

    @ViewBuilder
    private var answerArea: some View {
        let disabled = engine.lastWasCorrect != nil
        if settings.answerStyle == .piano {
            PianoKeyboardView(showLabels: settings.showKeyLabels,
                              accidentalsOn: config.accidentals,
                              useFlats: settings.useFlats,
                              useSolfege: settings.noteNameStyle.useSolfege,
                              disabled: disabled,
                              onAnswer: handleAnswer)
        } else {
            NoteButtonsView(useSolfege: settings.noteNameStyle.useSolfege,
                            accidentalsOn: config.accidentals,
                            useFlats: settings.useFlats,
                            disabled: disabled,
                            onAnswer: handleAnswer)
        }
    }

    private func handleAnswer(_ letter: String, _ accidental: Accidental) {
        guard engine.lastWasCorrect == nil else { return }
        let answeredMidi = engine.currentMIDI
        _ = engine.submit(letter: letter, accidental: accidental)
        if settings.soundEnabled {
            ToneSynth.shared.play(midi: answeredMidi)
        }
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.12)) { flash = true }
        }
        // Brief feedback hold, then advance.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            flash = false
            engine.advance()
        }
    }
}
