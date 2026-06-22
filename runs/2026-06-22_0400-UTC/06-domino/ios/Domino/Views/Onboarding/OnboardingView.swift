import SwiftUI

struct OnboardingView: View {
    let settings: DominoSettings
    let engine: DominoEngine
    @State private var page = 0
    @State private var selectedDifficulty: DominoEngine.AIDifficulty = .medium

    var body: some View {
        TabView(selection: $page) {
            page1.tag(0)
            page2.tag(1)
            page3.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(DominoTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .animation(.easeInOut, value: page)
    }

    private var page1: some View {
        VStack(spacing: 32) {
            Spacer()
            TileView(tile: .init(high: 6, low: 6), isDouble: true)
                .scaleEffect(1.4)
            Text("Domino")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(DominoTheme.ivory)
            Text("Classic Draw Dominoes vs. an adaptive AI opponent. Place tiles, block your rival, and be first to 100 points.")
                .font(.body)
                .foregroundStyle(DominoTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button { withAnimation { page = 1 } } label: {
                Text("Let's Play")
                    .font(.headline)
                    .foregroundStyle(DominoTheme.ebony)
                    .frame(maxWidth: .infinity).padding()
                    .background(DominoTheme.ivory, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }

    private var page2: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "cpu.fill")
                .font(.system(size: 64))
                .foregroundStyle(DominoTheme.amber)
            Text("Choose Difficulty")
                .font(.title.weight(.bold))
                .foregroundStyle(DominoTheme.ivory)
            VStack(spacing: 12) {
                ForEach(DominoEngine.AIDifficulty.allCases, id: \.self) { diff in
                    DifficultyRow(diff: diff, isSelected: selectedDifficulty == diff) {
                        selectedDifficulty = diff
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
            Button { withAnimation { page = 2 } } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(DominoTheme.ebony)
                    .frame(maxWidth: .infinity).padding()
                    .background(DominoTheme.ivory, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }

    private var page3: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "info.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(DominoTheme.green)
            Text("How to Play")
                .font(.title.weight(.bold))
                .foregroundStyle(DominoTheme.ivory)
            VStack(alignment: .leading, spacing: 12) {
                RuleRow(icon: "1.circle.fill", text: "Draw 7 tiles each. Highest double goes first.")
                RuleRow(icon: "2.circle.fill", text: "Match tile ends to play. Draw from boneyard if you can't.")
                RuleRow(icon: "3.circle.fill", text: "Score points equal to tiles left in opponent's hand.")
                RuleRow(icon: "4.circle.fill", text: "First to 100 points wins the match!")
            }
            .padding(.horizontal, 32)
            Spacer()
            Button {
                settings.difficulty = selectedDifficulty.rawValue
                settings.hasCompletedOnboarding = true
            } label: {
                Text("Start Match")
                    .font(.headline)
                    .foregroundStyle(DominoTheme.ebony)
                    .frame(maxWidth: .infinity).padding()
                    .background(DominoTheme.ivory, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }
}

private struct DifficultyRow: View {
    let diff: DominoEngine.AIDifficulty
    let isSelected: Bool
    let action: () -> Void

    var color: Color {
        switch diff {
        case .easy: return DominoTheme.green
        case .medium: return DominoTheme.amber
        case .hard: return DominoTheme.red
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Circle().fill(color).frame(width: 12, height: 12)
                Text(diff.displayName).font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(color)
                }
            }
            .padding()
            .background(isSelected ? color.opacity(0.2) : DominoTheme.card, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(DominoTheme.ivory)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? color : Color.clear, lineWidth: 1.5))
        }
    }
}

private struct RuleRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(DominoTheme.amber).frame(width: 24)
            Text(text).font(.subheadline).foregroundStyle(DominoTheme.secondaryText)
        }
    }
}
