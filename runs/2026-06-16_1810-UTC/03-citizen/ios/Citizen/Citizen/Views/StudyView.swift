import SwiftUI
import SwiftData

/// Study tab: a flashcard browser by category with flip-to-reveal, mark Known /
/// Needs review / Flag, and optional read-aloud (Pro).
struct StudyView: View {
    @Query private var stats: [QuestionStat]
    @Environment(\.modelContext) private var context
    @Environment(AppPreferences.self) private var prefs
    @Environment(SpeechManager.self) private var speech
    @Environment(\.colorScheme) private var scheme

    @State private var selectedCategory: CivicsCategory?
    @State private var seniorOnly = false
    @State private var index = 0
    @State private var isFlipped = false
    @State private var showPaywall = false

    private var store: StatStore { StatStore(context: context) }
    private var statsByNumber: [Int: QuestionStat] {
        Dictionary(stats.map { ($0.questionNumber, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var deck: [CivicsQuestion] {
        var qs = CivicsContent.questions
        if let cat = selectedCategory {
            qs = qs.filter { $0.category == cat }
        }
        if seniorOnly {
            qs = qs.filter { CivicsContent.seniorExemptionNumbers.contains($0.number) }
        }
        return qs
    }

    private var currentQuestion: CivicsQuestion? {
        guard !deck.isEmpty, index >= 0, index < deck.count else { return nil }
        return deck[index]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                filterBar

                if deck.isEmpty {
                    Spacer()
                    EmptyStateView(
                        systemImage: "rectangle.on.rectangle.slash",
                        title: "No cards here",
                        message: "No questions match this filter. Try another category or turn off the 65/20 filter."
                    )
                    Spacer()
                } else if let question = currentQuestion {
                    Spacer(minLength: 0)
                    FlashcardView(
                        question: question,
                        isFlipped: $isFlipped,
                        stat: statsByNumber[question.number],
                        audioEnabled: prefs.audioEnabled,
                        isPro: prefs.isPro,
                        onReadAloud: { readAloud(question) },
                        onUpgrade: { showPaywall = true }
                    )
                    .padding(.horizontal)

                    counter(question)
                    controls(question)
                    Spacer(minLength: 0)
                }
            }
            .padding(.vertical)
            .screenBackground(scheme)
            .navigationTitle("Study")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: selectedCategory) { _, _ in resetDeck() }
            .onChange(of: seniorOnly) { _, _ in resetDeck() }
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(title: "All", systemImage: "square.grid.2x2",
                                 isSelected: selectedCategory == nil) {
                        selectCategory(nil)
                    }
                    ForEach(CivicsCategory.allCases) { cat in
                        CategoryChip(title: cat.shortTitle, systemImage: cat.systemImage,
                                     isSelected: selectedCategory == cat) {
                            selectCategory(cat)
                        }
                    }
                }
                .padding(.horizontal)
            }
            if prefs.seniorExemption {
                Toggle("Show only the 20 senior-exemption questions", isOn: $seniorOnly)
                    .font(.footnote)
                    .tint(Theme.accent)
                    .padding(.horizontal)
            }
        }
    }

    private func selectCategory(_ cat: CivicsCategory?) {
        // Category browsing beyond "All" is a Pro feature; gate gracefully.
        if cat != nil && !prefs.isPro {
            showPaywall = true
            return
        }
        selectedCategory = cat
    }

    // MARK: - Counter + controls

    private func counter(_ question: CivicsQuestion) -> some View {
        HStack {
            Text("Card \(index + 1) of \(deck.count)")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary(scheme))
            Spacer()
            Button {
                _ = store.toggleFlag(question.number)
                Haptics.light(enabled: prefs.hapticsEnabled)
            } label: {
                Image(systemName: statsByNumber[question.number]?.isFlagged == true ? "flag.fill" : "flag")
                    .foregroundStyle(statsByNumber[question.number]?.isFlagged == true ? Theme.federalRed : Theme.textSecondary(scheme))
            }
            .accessibilityLabel(statsByNumber[question.number]?.isFlagged == true ? "Unflag question" : "Flag question")
        }
        .padding(.horizontal, 24)
    }

    private func controls(_ question: CivicsQuestion) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    store.markNeedsReview(question.number)
                    Haptics.light(enabled: prefs.hapticsEnabled)
                    next()
                } label: {
                    Label("Needs review", systemImage: "arrow.uturn.left")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.federalRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: Theme.corner)
                            .strokeBorder(Theme.federalRed.opacity(0.5), lineWidth: 1.5))
                }
                Button {
                    store.markKnown(question.number)
                    Haptics.success(enabled: prefs.hapticsEnabled)
                    next()
                } label: {
                    Label("I know it", systemImage: "checkmark")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: Theme.corner)
                            .fill(Theme.success(scheme)))
                }
            }
            HStack {
                Button {
                    previous()
                } label: {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .disabled(index == 0)
                .foregroundStyle(index == 0 ? Theme.textSecondary(scheme).opacity(0.5) : Theme.accent)
                Spacer()
                Button {
                    next()
                } label: {
                    Text("Skip")
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(Theme.accent)
            }
            .font(.subheadline)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func readAloud(_ question: CivicsQuestion) {
        let answer = question.varies
            ? (question.note ?? question.primaryAnswer)
            : question.acceptableAnswers.prefix(3).joined(separator: ", ")
        speech.speak("\(question.prompt). \(answer)")
    }

    private func next() {
        guard !deck.isEmpty else { return }
        isFlipped = false
        index = (index + 1) % deck.count
    }

    private func previous() {
        guard index > 0 else { return }
        isFlipped = false
        index -= 1
    }

    private func resetDeck() {
        index = 0
        isFlipped = false
        speech.stop()
    }
}

// MARK: - Flashcard

/// A single flippable flashcard. Calm 3D flip; static under Reduce Motion.
struct FlashcardView: View {
    let question: CivicsQuestion
    @Binding var isFlipped: Bool
    let stat: QuestionStat?
    let audioEnabled: Bool
    let isPro: Bool
    let onReadAloud: () -> Void
    let onUpgrade: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if isFlipped {
                back
                    .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            } else {
                front
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .rotation3DEffect(.degrees(isFlipped && !reduceMotion ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: isFlipped)
        .onTapGesture { isFlipped.toggle() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFlipped ? "Answer side" : "Question side")
        .accessibilityValue(isFlipped ? answerText : question.prompt)
        .accessibilityHint("Double tap to flip the card")
        .accessibilityAddTraits(.isButton)
    }

    private var front: some View {
        cardShell {
            VStack(spacing: 16) {
                header(label: "Q\(question.number) \u{00B7} \(question.section.title)")
                Spacer()
                Text(question.prompt)
                    .font(Theme.serifTitle(24, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text("Tap to reveal")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
        }
    }

    private var back: some View {
        cardShell(secondary: true) {
            VStack(alignment: .leading, spacing: 14) {
                header(label: question.varies ? "Answer varies" : "Acceptable answers")
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if question.varies {
                            Label(question.note ?? "Answer depends on your state or current officials.",
                                  systemImage: "mappin.and.ellipse")
                                .font(.callout)
                                .foregroundStyle(Theme.textPrimary(scheme))
                        } else {
                            ForEach(question.acceptableAnswers, id: \.self) { ans in
                                Label(ans, systemImage: "checkmark.circle.fill")
                                    .font(.callout)
                                    .foregroundStyle(Theme.textPrimary(scheme))
                            }
                            if let note = question.note {
                                Text(note)
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSecondary(scheme))
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 0)
                readAloudButton
            }
        }
    }

    private var readAloudButton: some View {
        Button {
            if isPro { onReadAloud() } else { onUpgrade() }
        } label: {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                Text("Read aloud")
                if !isPro { ProBadge() }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.accent)
        }
        .opacity(audioEnabled ? 1 : 0.4)
        .disabled(!audioEnabled)
        .accessibilityHint(isPro ? "Speaks the question and answer" : "Pro feature")
    }

    private func header(label: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)
                .lineLimit(1)
            Spacer()
            if let stat {
                MasteryDots(level: stat.masteryLevel)
            }
        }
    }

    private func cardShell<Content: View>(secondary: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 280)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(secondary ? Theme.cardSecondary(scheme) : Theme.card(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.08), radius: 8, y: 4)
    }

    private var answerText: String {
        if question.varies {
            return question.note ?? "Answer varies by state or current officials."
        }
        return question.acceptableAnswers.joined(separator: ", ")
    }
}
