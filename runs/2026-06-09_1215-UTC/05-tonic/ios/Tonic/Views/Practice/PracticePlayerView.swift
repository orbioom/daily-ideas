import SwiftUI
import SwiftData

/// The core ear-training loop for one drill: play the question, pick an answer,
/// get immediate feedback, advance, and save a session on End.
struct PracticePlayerView: View {
    let drill: Drill

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var stats: [ItemStat]

    @State private var question: Question?
    @State private var chosenRaw: String?
    @State private var isCorrect: Bool?
    @State private var isPlaying = false
    @State private var sessionTotal = 0
    @State private var sessionCorrect = 0
    @State private var startedAt = Date()
    @State private var audioFailed = false
    @State private var showEndConfirm = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                scoreHeader
                if audioFailed {
                    audioErrorCard
                }
                playCard
                if let q = question {
                    answerGrid(for: q)
                    if isCorrect != nil { feedbackCard(for: q) }
                }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(drill.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") { endSession() }
                    .disabled(sessionTotal == 0)
            }
        }
        .onAppear {
            if question == nil { nextQuestion(autoPlay: true) }
        }
    }

    // MARK: - Sections

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: drill.type.label)
                Text("Score")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            Text("\(sessionCorrect) / \(sessionTotal)")
                .font(Brand.mono(26, weight: .semibold))
                .foregroundStyle(Brand.text)
                .accessibilityLabel("Score")
                .accessibilityValue("\(sessionCorrect) correct out of \(sessionTotal)")
        }
        .glassCard(padding: 16)
    }

    private var audioErrorCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "speaker.slash")
                .font(.title2)
                .foregroundStyle(Brand.warn)
                .accessibilityHidden(true)
            Text("Couldn't start audio")
                .font(.headline)
                .foregroundStyle(Brand.text)
            Text("Check the silent switch and volume, then tap Play again.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 16)
        .accessibilityElement(children: .combine)
    }

    private var playCard: some View {
        VStack(spacing: 14) {
            Button {
                playQuestion()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isPlaying ? "waveform" : (question != nil ? "arrow.clockwise" : "play.fill"))
                        .symbolEffect(.variableColor, isActive: isPlaying && !reduceMotion)
                    Text(isPlaying ? "Playing…" : (chosenRaw == nil ? "Play" : "Replay"))
                }
            }
            .buttonStyle(InkButtonStyle())
            .disabled(isPlaying || question == nil)
            .accessibilityLabel(chosenRaw == nil ? "Play the question" : "Replay the question")
            .accessibilityHint("Sounds the notes you need to identify")

            Text(directionHint)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard(padding: 18)
    }

    private var directionHint: String {
        switch question?.style {
        case .sequenceAscending: return "Listen — notes ascending"
        case .sequenceDescending: return "Listen — notes descending"
        case .simultaneous: return "Listen — notes together"
        case .none: return "Tap Play to hear the question"
        }
    }

    private func answerGrid(for q: Question) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(q.choices, id: \.raw) { choice in
                answerButton(choice: choice, question: q)
            }
        }
    }

    private func answerButton(choice: (raw: String, label: String), question q: Question) -> some View {
        let answered = chosenRaw != nil
        let isChosen = chosenRaw == choice.raw
        let isAnswer = q.itemKey == choice.raw
        return Button {
            answer(choice.raw, for: q)
        } label: {
            Text(choice.label)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 30)
        }
        .buttonStyle(AnswerButtonStyle(state: buttonState(answered: answered,
                                                          isChosen: isChosen,
                                                          isAnswer: isAnswer)))
        .disabled(answered || isPlaying)
        .accessibilityLabel(choice.label)
        .accessibilityHint("Answer choice")
        .accessibilityAddTraits(answered && isAnswer ? .isSelected : [])
    }

    private func buttonState(answered: Bool, isChosen: Bool, isAnswer: Bool) -> AnswerButtonStyle.State {
        guard answered else { return .idle }
        if isAnswer { return .correct }
        if isChosen { return .wrong }
        return .dimmed
    }

    private func feedbackCard(for q: Question) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                StatusDot(color: (isCorrect ?? false) ? Brand.live : Brand.danger)
                Text((isCorrect ?? false) ? "Correct" : "Not quite")
                    .font(.headline)
                    .foregroundStyle(Brand.text)
            }
            if !(isCorrect ?? false) {
                Text("It was \(q.answerLabel).")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            Button {
                nextQuestion(autoPlay: true)
            } label: {
                Label("Next", systemImage: "arrow.right")
            }
            .buttonStyle(GlassButtonStyle())
        }
        .glassCard(padding: 16)
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel((isCorrect ?? false) ? "Correct" : "Incorrect, it was \(q.answerLabel)")
    }

    // MARK: - Actions

    private func nextQuestion(autoPlay: Bool) {
        chosenRaw = nil
        withAnimation(reduceMotion ? nil : Brand.ease(0.3)) { isCorrect = nil }
        guard let q = EarEngine.makeQuestion(for: drill, stats: stats) else { return }
        question = q
        if autoPlay { playQuestion() }
    }

    private func playQuestion() {
        guard let q = question, !isPlaying else { return }
        ToneSynth.shared.playFrequencies(q.frequencies, style: q.style)
        // If the engine never started, surface the calm error.
        audioFailed = !ToneSynth.shared.isAvailable
        guard !audioFailed else { return }
        let dur = ToneSynth.shared.estimatedDuration(noteCount: q.frequencies.count, style: q.style)
        isPlaying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.1) {
            isPlaying = false
        }
    }

    private func answer(_ raw: String, for q: Question) {
        guard chosenRaw == nil else { return }
        let correct = EarEngine.grade(question: q, chosenRaw: raw)
        chosenRaw = raw
        withAnimation(reduceMotion ? nil : Brand.ease(0.3)) { isCorrect = correct }
        sessionTotal += 1
        if correct { sessionCorrect += 1 }
        if correct { Haptics.success() } else { Haptics.warning() }
        recordStat(key: q.statKey, correct: correct)
    }

    private func recordStat(key: String, correct: Bool) {
        let descriptor = FetchDescriptor<ItemStat>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.attempts += 1
            if correct { existing.correct += 1 }
            existing.lastSeen = .now
        } else {
            context.insert(ItemStat(key: key, attempts: 1, correct: correct ? 1 : 0))
        }
        try? context.save()
    }

    private func endSession() {
        guard sessionTotal > 0 else { dismiss(); return }
        let dur = Int(Date().timeIntervalSince(startedAt))
        context.insert(DrillSession(drillName: drill.name,
                                    drillType: drill.type,
                                    total: sessionTotal,
                                    correct: sessionCorrect,
                                    durationSec: dur))
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

/// Answer-button styling with correct / wrong / dimmed feedback states.
struct AnswerButtonStyle: ButtonStyle {
    enum State { case idle, correct, wrong, dimmed }
    let state: State
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1.2)
            )
            .opacity(state == .dimmed ? 0.5 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(Brand.ease(0.2), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch state {
        case .correct: return Brand.live
        case .wrong: return Brand.danger
        default: return Brand.text
        }
    }
    private var stroke: Color {
        switch state {
        case .correct: return Brand.live.opacity(0.8)
        case .wrong: return Brand.danger.opacity(0.8)
        default: return Brand.glassStroke.opacity(0.5)
        }
    }
    private var background: AnyShapeStyle {
        switch state {
        case .correct: return AnyShapeStyle(Brand.live.opacity(0.12))
        case .wrong: return AnyShapeStyle(Brand.danger.opacity(0.12))
        default: return AnyShapeStyle(.ultraThinMaterial)
        }
    }
}
