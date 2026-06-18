import SwiftUI
import SwiftData

/// The core game screen: honeycomb, current word, controls, found words, rank progress.
struct PlayView: View {
    let puzzle: Puzzle

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @State private var model: GameViewModel?
    @State private var showHints = false
    @State private var showPaywall = false
    @State private var wordShake = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            content
            overlays
        }
        .navigationTitle(puzzle.isDaily ? "Daily" : "Practice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if pro.isPro { showHints = true } else { showPaywall = true }
                } label: {
                    Image(systemName: "lightbulb.max")
                        .accessibilityLabel("Hints")
                }
            }
        }
        .sheet(isPresented: $showHints) {
            if let model {
                HintsView(puzzle: puzzle, foundWords: model.foundSet)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            if model == nil {
                model = GameViewModel(puzzle: puzzle, context: context)
            }
        }
        .task(id: model?.lastResultToken) {
            guard model?.lastResult != nil else { return }
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            model?.clearFeedback()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let model {
            ScrollView {
                VStack(spacing: 18) {
                    RankProgressBar(
                        score: model.score,
                        maxScore: puzzle.totalPossibleScore,
                        reduceMotion: reduceMotion
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    currentWordView(model)

                    HoneycombBoard(
                        center: puzzle.center,
                        outer: model.displayOrder,
                        colorBlindSafe: settings.colorBlindSafe,
                        reduceMotion: reduceMotion,
                        onTap: { ch in
                            Haptics.selection(enabled: settings.hapticsEnabled)
                            model.append(ch)
                        }
                    )
                    .frame(height: 320)

                    controls(model)

                    SectionCard {
                        FoundWordsDrawer(words: model.foundWords, letterSet: puzzle.letterSet)
                    }
                    .padding(.horizontal, 18)

                    if model.isComplete {
                        completeBanner
                            .padding(.horizontal, 18)
                    }

                    Color.clear.frame(height: 12)
                }
            }
        } else {
            ProgressView("Loading puzzle…")
                .tint(Theme.accent)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func currentWordView(_ model: GameViewModel) -> some View {
        HStack(spacing: 2) {
            if model.typed.isEmpty {
                Text("Type a word")
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
            } else {
                ForEach(Array(model.typed.uppercased().enumerated()), id: \.offset) { _, ch in
                    Text(String(ch))
                        .font(Theme.rounded(30, .heavy))
                        .foregroundStyle(letterColor(ch))
                }
            }
        }
        .frame(height: 40)
        .offset(x: wordShake && !reduceMotion ? -8 : 0)
        .animation(reduceMotion ? nil : .default, value: model.typed)
        .accessibilityLabel(model.typed.isEmpty ? "No letters typed" : "Current word \(model.typed)")
    }

    private func letterColor(_ ch: Character) -> Color {
        let lower = Character(ch.lowercased())
        if lower == puzzle.center { return Theme.accentDeep }
        if puzzle.letterSet.contains(lower) { return Theme.ink }
        return Theme.bad
    }

    private func controls(_ model: GameViewModel) -> some View {
        HStack(spacing: 14) {
            circleButton(symbol: "delete.left", label: "Delete") {
                Haptics.impact(.light, enabled: settings.hapticsEnabled)
                model.deleteLast()
            }
            .disabled(model.typed.isEmpty)

            Button {
                submit(model)
            } label: {
                Text("Enter")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Theme.accent))
            }
            .accessibilityLabel("Enter word")
            .accessibilityHint("Submits the current word")

            circleButton(symbol: "shuffle", label: "Shuffle letters") {
                Haptics.impact(.light, enabled: settings.hapticsEnabled)
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                    model.shuffleOuter()
                }
            }
        }
        .padding(.horizontal, 18)
    }

    private func circleButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Theme.surface))
                .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }

    private var completeBanner: some View {
        SectionCard {
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Queen Bee!")
                    .font(Theme.rounded(22, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("You found every word. Masterful.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
    }

    private func submit(_ model: GameViewModel) {
        let result = model.submit()
        switch result {
        case .accepted(_, let isPangram):
            Haptics.notify(isPangram ? .success : .success, enabled: settings.hapticsEnabled)
        default:
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            if !reduceMotion {
                withAnimation(.spring(response: 0.18, dampingFraction: 0.25)) { wordShake = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.25)) { wordShake = false }
                }
            }
        }
    }

    @ViewBuilder
    private var overlays: some View {
        if let model {
            VStack {
                Spacer()
                if let result = model.lastResult {
                    feedbackToast(for: result)
                        .id(model.lastResultToken)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 90)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: model.lastResultToken)
            .allowsHitTesting(false)

            if settings.showRankToasts, let toast = model.pendingRankToast {
                RankToastOverlay(rank: toast, reduceMotion: reduceMotion) {
                    model.pendingRankToast = nil
                }
            }
        }
    }

    @ViewBuilder
    private func feedbackToast(for result: ValidationResult) -> some View {
        switch result {
        case .accepted(let points, let isPangram):
            ToastView(text: isPangram ? "Pangram! +\(points)" : "+\(points)", kind: .success)
        case .alreadyFound:
            ToastView(text: result.message, kind: .warn)
        default:
            ToastView(text: result.message, kind: .error)
        }
    }
}
