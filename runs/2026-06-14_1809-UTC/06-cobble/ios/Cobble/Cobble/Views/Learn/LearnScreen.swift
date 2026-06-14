import SwiftUI

/// How to Play: clear, illustrated rules — placing, clearing rows/cols, combos, scoring,
/// game-over, plus tips. Real content (mini board diagrams), not filler.
struct LearnScreen: View {
    private let palette = BlockPalettes.classic

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    placingCard
                    clearingCard
                    comboCard
                    scoringCard
                    gameOverCard
                    tipsCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("How to Play")
        }
    }

    private var intro: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("The goal")
                    .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                Text("Drop block shapes onto the 8×8 grid. Completely fill any row or column and it clears, making room for more. There's no timer — play until no piece in your tray fits anywhere.")
                    .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var placingCard: some View {
        ruleCard(number: 1, title: "Place a piece",
                 body: "Tap a piece in the tray to pick it up — it highlights. Tap (or press and slide) on the board to see a ghost: green where it fits, red where it doesn't. Tap a green spot to drop it.") {
            MiniBoard(rows: 4, cols: 6, palette: palette, fills: [
                MiniBoard.Fill(2, 2, 1, ghost: .valid),
                MiniBoard.Fill(2, 3, 1, ghost: .valid),
                MiniBoard.Fill(3, 2, 1, ghost: .valid),
                MiniBoard.Fill(3, 3, 1, ghost: .valid)
            ])
        }
    }

    private var clearingCard: some View {
        ruleCard(number: 2, title: "Clear rows & columns",
                 body: "When a full row or column has no gaps, it clears. Both a row and a column can clear from a single placement — the cell where they cross counts once.") {
            MiniBoard(rows: 4, cols: 6, palette: palette, fills:
                (0..<6).map { MiniBoard.Fill(1, $0, 2, ghost: .flash) }
            )
        }
    }

    private var comboCard: some View {
        ruleCard(number: 3, title: "Build combos",
                 body: "Clear at least one line on consecutive placements to grow your combo. Each step in the combo multiplies your line bonus — up to 4×. Place a piece without clearing and the combo resets.") {
            HStack(spacing: 10) {
                comboPill("×1", Theme.inkSoft)
                Image(systemName: "arrow.right").foregroundStyle(Theme.inkFaint)
                comboPill("×1.5", Theme.accent)
                Image(systemName: "arrow.right").foregroundStyle(Theme.inkFaint)
                comboPill("×2", Theme.good)
            }
        }
    }

    private var scoringCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Label("Scoring", systemImage: "number.circle.fill")
                    .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                scoreRow("Each cell you place", "+1 point")
                Divider().overlay(Theme.hairline)
                scoreRow("Clearing lines", "10 × lines × lines, then × combo")
                Divider().overlay(Theme.hairline)
                Text("Example: clearing 2 lines on a ×2 combo earns 10 × 2 × 2 × 2 = 80 line points, plus the cells you placed.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var gameOverCard: some View {
        ruleCard(number: 4, title: "Game over",
                 body: "The game ends when none of the three pieces in your tray can fit anywhere on the board. Plan ahead and keep open space — big pieces need room. Undo lets you take a placement back.") {
            MiniBoard(rows: 3, cols: 6, palette: palette, fills: [
                MiniBoard.Fill(0, 0, 3), MiniBoard.Fill(0, 2, 4), MiniBoard.Fill(0, 4, 5),
                MiniBoard.Fill(1, 1, 6), MiniBoard.Fill(1, 3, 3), MiniBoard.Fill(1, 5, 4),
                MiniBoard.Fill(2, 0, 5), MiniBoard.Fill(2, 2, 6), MiniBoard.Fill(2, 4, 3)
            ])
        }
    }

    private var tipsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Label("Tips", systemImage: "lightbulb.fill")
                    .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                tip("Keep a clear lane open for the long 1×5 bars.")
                tip("Work from the edges toward the centre to avoid trapping holes.")
                tip("Set up two lines to clear together for a bigger bonus.")
                tip("The Daily uses the same pieces for everyone — compare your best!")
            }
        }
    }

    // MARK: Building blocks

    private func ruleCard<Diagram: View>(number: Int, title: String, body: String,
                                         @ViewBuilder diagram: () -> Diagram) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text("\(number)")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Theme.accent))
                    Text(title).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                }
                Text(body).font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                diagram()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
            }
        }
    }

    private func comboPill(_ text: String, _ tint: Color) -> some View {
        Text(text)
            .font(Theme.rounded(15, .bold)).foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(tint))
    }

    private func scoreRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(14)).foregroundStyle(Theme.ink)
            Spacer()
            Text(value).font(Theme.mono(13, .semibold)).foregroundStyle(Theme.accent)
        }
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13)).foregroundStyle(Theme.good)
                .padding(.top, 2)
            Text(text).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
