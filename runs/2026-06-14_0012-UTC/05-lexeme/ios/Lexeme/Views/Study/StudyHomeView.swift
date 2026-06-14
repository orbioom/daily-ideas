import SwiftUI
import SwiftData

/// Entry point for studying: a big "Start Review" CTA plus per-mode practice,
/// honoring the free-tier daily review cap and Pro-gated modes.
struct StudyHomeView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @AppStorage("dailyReviewGoal") private var dailyGoal = 20
    @AppStorage("typedFillBlank") private var typedFillBlank = false
    @AppStorage("reviewsDoneDate") private var reviewsDoneDate = ""
    @AppStorage("reviewsDoneCount") private var reviewsDoneCount = 0

    @State private var dueCount = 0
    @State private var showPaywall = false
    @State private var activeSession: SessionRequest?

    /// Free tier daily review cap.
    private let freeDailyCap = 20

    private var store: ProgressStore { ProgressStore(context: context) }

    private var reviewsRemaining: Int {
        guard !isPro else { return Int.max }
        let today = LexemeEngine.dayKey(Date())
        let done = reviewsDoneDate == today ? reviewsDoneCount : 0
        return max(0, freeDailyCap - done)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        reviewCard
                        modesSection
                        if !isPro { upgradeNote }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Study")
            .navigationDestination(item: $activeSession) { req in
                QuizPlayerView(request: req, onFinish: { onSessionFinished($0) })
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear { refresh() }
        }
    }

    private func refresh() {
        dueCount = store.allProgress().filter { LexemeEngine.isDue($0) }.count
    }

    // MARK: - Review card

    private var reviewCard: some View {
        LexemeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionLabel(text: "Adaptive review")
                    Spacer()
                    if !isPro {
                        Text("\(reviewsRemaining) left today")
                            .font(Theme.rounded(12, .medium))
                            .foregroundStyle(reviewsRemaining == 0 ? Theme.bad : Theme.inkSoft)
                    }
                }
                Text(dueCount > 0 ? "\(dueCount) words ready to review" : "Nothing due — start a fresh round")
                    .font(Theme.serif(22, .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("A mixed session that resurfaces due words and introduces new ones, in the modes your plan allows.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                if reviewsRemaining == 0 {
                    Button { showPaywall = true } label: {
                        Label("Daily limit reached — Unlock unlimited", systemImage: "lock.fill")
                            .font(Theme.rounded(15, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.gold.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(Theme.gold)
                    }
                    .buttonStyle(.plain)
                } else {
                    PrimaryButton(title: "Start Review", systemImage: "play.fill") {
                        Haptics.tap()
                        startReview()
                    }
                }
            }
        }
    }

    private func startReview() {
        let limit = sessionLimit(base: max(dailyGoal, 5))
        activeSession = SessionRequest(mode: nil,
                                       allowedModes: availableModes,
                                       limit: limit,
                                       typedFillBlank: typedFillBlank)
    }

    // MARK: - Modes

    private var availableModes: [QuizMode] {
        QuizMode.allCases.filter { isPro || !$0.requiresPro }
    }

    private var modesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Practice one mode")
                .padding(.leading, 4)
            ForEach(QuizMode.allCases) { mode in
                modeRow(mode)
            }
        }
    }

    private func modeRow(_ mode: QuizMode) -> some View {
        let locked = mode.requiresPro && !isPro
        return Button {
            Haptics.tap()
            if locked {
                showPaywall = true
            } else if reviewsRemaining == 0 {
                showPaywall = true
            } else {
                activeSession = SessionRequest(mode: mode,
                                               allowedModes: [mode],
                                               limit: sessionLimit(base: 10),
                                               typedFillBlank: typedFillBlank)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(locked ? Theme.inkFaint : Theme.accent)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle(for: mode))
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if locked { ProLockBadge() }
                else { Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.inkFaint) }
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityHint(locked ? "Requires Lexeme Pro" : "Starts a \(mode.title) session")
    }

    private func subtitle(for mode: QuizMode) -> String {
        switch mode {
        case .definitionToWord: return "Read a meaning, choose the word"
        case .wordToDefinition: return "Read a word, choose its meaning"
        case .synonymMatch:     return "Pick the true synonym"
        case .fillBlank:        return typedFillBlank ? "Type the missing word" : "Fill the blank from choices"
        }
    }

    private var upgradeNote: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles").foregroundStyle(Theme.gold)
                Text("Lexeme Pro: unlimited reviews, all modes, SAT & GRE banks.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.inkFaint)
            }
            .padding(14)
            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily cap accounting

    /// Caps a requested session size by reviews remaining today (free tier).
    private func sessionLimit(base: Int) -> Int {
        guard !isPro else { return base }
        return max(1, min(base, reviewsRemaining))
    }

    private func onSessionFinished(_ answered: Int) {
        refresh()
        guard !isPro else { return }
        let today = LexemeEngine.dayKey(Date())
        if reviewsDoneDate != today {
            reviewsDoneDate = today
            reviewsDoneCount = 0
        }
        reviewsDoneCount += answered
    }
}

/// A request to start a quiz session, passed via navigationDestination.
struct SessionRequest: Identifiable, Hashable {
    let id = UUID()
    let mode: QuizMode?
    let allowedModes: [QuizMode]
    let limit: Int
    let typedFillBlank: Bool
}
