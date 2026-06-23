import SwiftUI
import SwiftData

/// A spaced-repetition flashcard session for one deck.
struct ReviewSessionView: View {
    let deck: Deck
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var settingsList: [AppSettings]

    @State private var model: ReviewSessionViewModel?
    @ObservedObject private var speech = SpeechManager.shared

    private var settings: AppSettings { settingsList.first ?? AppSettings() }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if let model {
                    switch model.phase {
                    case .loading:
                        loadingState
                    case .empty:
                        emptyState
                    case .studying:
                        studying(model)
                    case .finished:
                        finishedState(model)
                    }
                } else {
                    loadingState
                }
            }
            .navigationTitle(deck.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        speech.stop()
                        dismiss()
                    }
                }
                if let model, model.phase == .studying {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(model.progressText)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                            .accessibilityLabel("Card \(model.progressText)")
                    }
                }
            }
        }
        .task {
            if model == nil {
                let vm = ReviewSessionViewModel(deck: deck, context: context, newLimit: settings.dailyNewLimit)
                model = vm
                await vm.start()
            }
        }
    }

    // MARK: States
    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.brand)
            Text("Building your review queue…")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading review session")
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: "checkmark.seal.fill",
            title: "Nothing due right now",
            message: "You've reviewed everything available in \(deck.name). Come back later or add new phrases.",
            actionTitle: "Close",
            action: { dismiss() }
        )
    }

    // MARK: Studying
    private func studying(_ model: ReviewSessionViewModel) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView(value: model.progressFraction)
                .tint(Theme.brand)
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer(minLength: 0)

            if let phrase = model.currentPhrase {
                FlashcardView(
                    phrase: phrase,
                    isRevealed: model.isRevealed,
                    showPronunciation: settings.showPronunciation,
                    reduceMotion: reduceMotion
                )
                .padding(.horizontal, Theme.Spacing.lg)
                .id(phrase.id)
            }

            Spacer(minLength: 0)

            controls(model)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
        }
    }

    @ViewBuilder
    private func controls(_ model: ReviewSessionViewModel) -> some View {
        if !model.isRevealed {
            VStack(spacing: Theme.Spacing.md) {
                Button {
                    speakCurrent(model)
                } label: {
                    Label("Hear it", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                        model.reveal()
                    }
                    if settings.autoSpeakOnReveal {
                        speakCurrent(model)
                    }
                } label: {
                    Label("Show answer", systemImage: "eye.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        } else {
            VStack(spacing: Theme.Spacing.sm) {
                Text("How well did you recall it?")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(ReviewGrade.allCases) { grade in
                        GradeButton(
                            grade: grade,
                            interval: model.intervalPreview(for: grade)
                        ) {
                            applyGrade(grade, model: model)
                        }
                    }
                }
            }
        }
    }

    private func applyGrade(_ grade: ReviewGrade, model: ReviewSessionViewModel) {
        if grade == .again {
            Haptics.warning(enabled: settings.hapticsEnabled)
        } else {
            Haptics.success(enabled: settings.hapticsEnabled)
        }
        speech.stop()
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            model.grade(grade)
        }
    }

    private func speakCurrent(_ model: ReviewSessionViewModel) {
        guard let phrase = model.currentPhrase else { return }
        speech.speak(phrase.target, localeIdentifier: deck.localeIdentifier, rate: settings.speechRate)
    }

    // MARK: Finished
    private func finishedState(_ model: ReviewSessionViewModel) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.success)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.sm) {
                Text("Session complete")
                    .font(.title.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("You reviewed \(model.gradedCount) \(model.gradedCount == 1 ? "card" : "cards").")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack(spacing: Theme.Spacing.xl) {
                ResultStat(value: model.goodCount, label: "Recalled", tint: Theme.success)
                ResultStat(value: model.againCount, label: "Missed", tint: Theme.warn)
            }
            Spacer()
            Button {
                speech.stop()
                dismiss()
            } label: { Text("Finish") }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ResultStat: View {
    let value: Int
    let label: String
    let tint: Color
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.system(size: 40, weight: .bold, design: .rounded)).foregroundStyle(tint)
            Text(label).font(.subheadline).foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

private struct GradeButton: View {
    let grade: ReviewGrade
    let interval: String
    let action: () -> Void

    private var tint: Color {
        switch grade {
        case .again: return Theme.warn
        case .hard: return Color.orange
        case .good: return Theme.success
        case .easy: return Theme.brandDeep
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: grade.symbol).font(.headline)
                Text(grade.title).font(.caption.bold())
                Text(interval).font(.caption2).opacity(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(tint, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(grade.title), next review in \(interval)")
    }
}

#Preview {
    if let container = PersistenceController.previewContainer(),
       let deck = (try? container.mainContext.fetch(FetchDescriptor<Deck>()))?.first {
        ReviewSessionView(deck: deck).modelContainer(container)
    }
}
