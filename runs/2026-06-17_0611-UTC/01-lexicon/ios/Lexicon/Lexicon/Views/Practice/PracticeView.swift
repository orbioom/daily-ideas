import SwiftUI

/// Practice tab: pick a word length and play endless random games. Length 6 is Pro.
struct PracticeView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false

    @State private var selectedLength = 5
    @State private var activeConfig: GameConfig?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                LexBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        intro
                        lengthPicker
                        startButton
                        tip
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Practice")
            .navigationDestination(item: $activeConfig) { config in
                GameBoardScreen(
                    config: config,
                    title: "Practice",
                    subtitle: "\(config.wordLength)-letter word",
                    allowReplay: true
                )
                .id(config.id)
                .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var intro: some View {
        LexCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Endless words", systemImage: "infinity")
                    .font(.headline)
                    .foregroundStyle(LexTheme.primaryText(scheme))
                Text("Play as many random puzzles as you like — no waiting for tomorrow. Your daily streak is unaffected.")
                    .font(.subheadline)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            }
        }
    }

    private var lengthPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Word length")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LexTheme.secondaryText(scheme))
            HStack(spacing: 10) {
                ForEach(WordLists.supportedLengths, id: \.self) { length in
                    lengthChip(length)
                }
            }
        }
    }

    private func lengthChip(_ length: Int) -> some View {
        let locked = !FreeTier.isLengthFree(length) && !isPro
        return Button {
            if locked {
                showPaywall = true
            } else {
                selectedLength = length
                Haptics.light()
            }
        } label: {
            HStack(spacing: 6) {
                Text("\(length)")
                if locked {
                    Image(systemName: "lock.fill").font(.caption2)
                }
            }
            .lexChip(selected: selectedLength == length && !locked)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(length) letters\(locked ? ", Pro locked" : "")")
        .accessibilityAddTraits(selectedLength == length && !locked ? .isSelected : [])
    }

    private var startButton: some View {
        Button {
            activeConfig = GameConfig.practice(length: selectedLength)
        } label: {
            Label("Start \(selectedLength)-letter game", systemImage: "play.fill")
        }
        .buttonStyle(LexPrimaryButtonStyle())
    }

    private var tip: some View {
        Text("Tip: finish a game to instantly start another.")
            .font(.caption)
            .foregroundStyle(LexTheme.secondaryText(scheme))
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
