import SwiftUI
import SwiftData

/// Full-screen study player. Shows a card, reveals the back (3D flip or cross-fade under
/// Reduce Motion), then grades via SRSEngine and advances. Handles flip / MCQ / type / cram.
struct StudyPlayerView: View {
    let config: StudyConfig

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var model: StudyViewModel

    init(config: StudyConfig) {
        self.config = config
        _model = State(initialValue: StudyViewModel(config: config))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if model.total == 0 {
                    emptyState
                } else if model.finished {
                    SessionSummaryView(model: model, title: config.title) { dismiss() }
                } else {
                    activeSession
                }
            }
        }
    }

    // MARK: - Top bar (progress + close)

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .padding(8)
                        .background(Circle().fill(Theme.surfaceAlt))
                }
                .accessibilityLabel("End session")

                Spacer()

                Text(config.title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: config.mode.systemImage)
                        .font(.system(size: 11, weight: .bold))
                    Text(config.mode.shortName)
                        .font(Theme.rounded(12, .semibold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(Theme.accentSoft))
                .accessibilityLabel("\(config.mode.display) mode")
            }

            if !model.finished && model.total > 0 {
                ProgressView(value: model.progress)
                    .tint(Theme.accent)
                    .accessibilityLabel("Progress")
                    .accessibilityValue("\(model.total - model.remaining) of \(model.total)")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Active session

    @ViewBuilder
    private var activeSession: some View {
        if let card = model.currentCard {
            VStack(spacing: 16) {
                Text("\(model.remaining) left")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkFaint)

                Spacer(minLength: 0)

                FlashcardView(card: card,
                              isRevealed: model.isRevealed,
                              reduceMotion: reduceMotion,
                              colorSeed: config.scopedDeck?.colorSeed ?? card.deck?.colorSeed ?? 0,
                              showFrontTapHint: model.mode == .flip || model.mode == .cram)

                Spacer(minLength: 0)

                interactionArea(for: card)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private func interactionArea(for card: Card) -> some View {
        switch model.mode {
        case .flip, .cram:
            flipControls
        case .multipleChoice:
            mcqControls(card: card)
        case .typeAnswer:
            typeControls(card: card)
        }
    }

    // MARK: Flip / Cram controls

    @ViewBuilder
    private var flipControls: some View {
        if model.isRevealed {
            gradeButtons
        } else {
            PrimaryButton(title: "Show answer", systemImage: "eye.fill") {
                withAnimation(flipAnimation) { model.reveal() }
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
        }
    }

    // MARK: MCQ controls

    @ViewBuilder
    private func mcqControls(card: Card) -> some View {
        VStack(spacing: 10) {
            ForEach(model.options, id: \.self) { option in
                mcqOptionButton(option: option, card: card)
            }
            if model.isRevealed {
                gradeButtons
                    .padding(.top, 4)
            }
        }
    }

    private func mcqOptionButton(option: String, card: Card) -> some View {
        let revealed = model.isRevealed
        let isCorrect = model.optionIsCorrect(option)
        let isChosen = model.selectedOption == option

        let fill: Color = {
            guard revealed else { return Theme.surface }
            if isCorrect { return Theme.good.opacity(0.18) }
            if isChosen { return Theme.bad.opacity(0.18) }
            return Theme.surface
        }()
        let border: Color = {
            guard revealed else { return Theme.hairline }
            if isCorrect { return Theme.good }
            if isChosen { return Theme.bad }
            return Theme.hairline
        }()

        return Button {
            model.chooseOption(option)
            Haptics.selection(enabled: settings.hapticsEnabled)
        } label: {
            HStack {
                Text(option)
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer()
                if revealed && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.good)
                } else if revealed && isChosen {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.bad)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).strokeBorder(border, lineWidth: 1.5))
        }
        .buttonStyle(PressableScale())
        .disabled(revealed)
        .accessibilityLabel(option)
        .accessibilityHint(revealed ? (isCorrect ? "Correct answer" : "") : "Tap to choose")
    }

    // MARK: Type controls

    @ViewBuilder
    private func typeControls(card: Card) -> some View {
        VStack(spacing: 12) {
            TextField("Type the answer", text: $model.typedAnswer)
                .textFieldStyle(.plain)
                .font(Theme.rounded(17))
                .padding(14)
                .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
                .disabled(model.isRevealed)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .onSubmit {
                    if !model.isRevealed { model.submitTyped() }
                }
                .accessibilityLabel("Answer field")

            if model.isRevealed {
                HStack(spacing: 8) {
                    Image(systemName: model.typedWasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(model.typedWasCorrect ? Theme.good : Theme.bad)
                    Text(model.typedWasCorrect ? "Correct!" : "Answer: \(card.back)")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                gradeButtons
            } else {
                PrimaryButton(title: "Check answer", systemImage: "checkmark") {
                    model.submitTyped()
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
            }
        }
    }

    // MARK: Grade buttons

    private var gradeButtons: some View {
        HStack(spacing: 8) {
            ForEach(Grade.allCases) { grade in
                gradeButton(grade)
            }
        }
    }

    private func gradeButton(_ grade: Grade) -> some View {
        let interval = model.intervalLabel(for: grade)
        let a11y = interval.isEmpty ? grade.display : "\(grade.display), next in \(interval)"
        return Button {
            model.grade(grade, context: context, hapticsEnabled: settings.hapticsEnabled)
        } label: {
            VStack(spacing: 3) {
                Text(grade.display)
                    .font(Theme.rounded(15, .bold))
                if !interval.isEmpty {
                    Text(interval)
                        .font(Theme.rounded(11, .medium))
                        .opacity(0.85)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(grade.color))
        }
        .buttonStyle(PressableScale())
        .accessibilityLabel(a11y)
    }

    private var flipAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.78)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateView(symbol: "checkmark.seal.fill",
                           title: "All caught up",
                           message: "There's nothing due in \(config.title) right now. Come back later, or use Cram from the Study tab to drill ahead.",
                           actionTitle: "Done") {
                dismiss()
            }
            Spacer()
        }
    }
}

#Preview {
    let deck = PreviewContainer.firstDeck()
    let queue = deck.map {
        StudyQueue.buildSessionQueue(cards: $0.cards, newLimit: 20, reviewLimit: 100, shuffle: false)
    } ?? []
    return StudyPlayerView(config: StudyConfig(title: deck?.name ?? "Deck",
                                               mode: .flip,
                                               queue: queue,
                                               distractorPool: deck?.activeCards ?? [],
                                               scopedDeck: deck))
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
