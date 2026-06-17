import SwiftUI

/// Rules screen: tile-state legend, hard-mode explanation, and quick tips.
struct HowToPlayView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.highContrastColors) private var highContrast: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LexBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        intro
                        legendCard
                        exampleCard
                        hardModeCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("How to Play")
        }
    }

    private var intro: some View {
        LexCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Guess the word in \(DailyPuzzle.maxGuesses) tries.")
                    .font(.headline)
                    .foregroundStyle(LexTheme.primaryText(scheme))
                Text("Each guess must be a real word of the right length. After each guess the tiles change color to show how close you were.")
                    .font(.subheadline)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            }
        }
    }

    private var legendCard: some View {
        LexCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Tile colors")
                    .font(.headline)
                    .foregroundStyle(LexTheme.primaryText(scheme))
                legendRow(.correct, letter: "L", title: "Correct", detail: "Right letter, right spot.")
                legendRow(.present, letter: "E", title: "In the word", detail: "Right letter, wrong spot.")
                legendRow(.absent, letter: "X", title: "Not in the word", detail: "This letter isn't used.")
            }
        }
    }

    private func legendRow(_ state: TileState, letter: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(state.fill(scheme: scheme, highContrast: highContrast))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(letter)
                        .font(LexTheme.display(20, weight: .heavy))
                        .foregroundStyle(.white)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LexTheme.primaryText(scheme))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail)")
    }

    private var exampleCard: some View {
        LexCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Example")
                    .font(.headline)
                    .foregroundStyle(LexTheme.primaryText(scheme))
                HStack(spacing: 6) {
                    exampleTile("W", .correct)
                    exampleTile("O", .absent)
                    exampleTile("R", .present)
                    exampleTile("D", .absent)
                    exampleTile("S", .absent)
                }
                .frame(maxWidth: 280)
                Text("W is in the word and in the right spot. R is in the word but somewhere else. O, D and S are not in the word.")
                    .font(.caption)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            }
        }
    }

    private func exampleTile(_ letter: String, _ state: TileState) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(state.fill(scheme: scheme, highContrast: highContrast))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Text(letter)
                    .font(LexTheme.display(22, weight: .heavy))
                    .foregroundStyle(.white)
            )
            .accessibilityHidden(true)
    }

    private var hardModeCard: some View {
        LexCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Hard mode", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(LexTheme.primaryText(scheme))
                Text("When hard mode is on (in Settings), any hint you've revealed must be used in later guesses: green letters must stay in place, and yellow letters must appear somewhere in your next guess.")
                    .font(.subheadline)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            }
        }
    }
}
