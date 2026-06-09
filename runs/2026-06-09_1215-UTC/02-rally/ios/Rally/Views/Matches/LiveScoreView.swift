import SwiftUI
import SwiftData

/// The live scoreboard. Tap +/- to score the current game for each side; the
/// `ScoreEngine` detects a finished game and the running games-won tally updates.
/// "Finish match" applies the `RatingEngine` and marks the match complete.
struct LiveScoreView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var match: Match

    @State private var showFinishConfirm = false
    @State private var showAbandonConfirm = false

    private var currentGame: GameScore? {
        match.orderedGames.last
    }

    private var gameWinner: ScoreEngine.Winner? {
        guard let g = currentGame else { return nil }
        return ScoreEngine.winner(myScore: g.myScore, oppScore: g.oppScore,
                                  pointsToWin: match.pointsToWin, winByTwo: match.winByTwo)
    }

    private var canFinish: Bool {
        // The tally already reflects every decided game (recomputed on each point),
        // so a finish is allowed once one side leads in games won.
        match.myGamesWon != match.oppGamesWon
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                gamesTally
                scoreboard
                controls
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Live")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Quit") {
                    Haptics.warning()
                    showAbandonConfirm = true
                }
            }
        }
        .confirmationDialog("Finish this match?", isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button("Finish & save", role: .none) { finish() }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("Final games \(match.myGamesWon)–\(match.oppGamesWon). Ratings update on save.")
        }
        .confirmationDialog("Discard this match?", isPresented: $showAbandonConfirm, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { abandon() }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("This in-progress match will be deleted and won't affect ratings.")
        }
    }

    // MARK: - Tally

    private var gamesTally: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sideShortName(match.myNames))
                    .font(.caption).foregroundStyle(Brand.text3).lineLimit(1)
                Text("\(match.myGamesWon)")
                    .font(Brand.mono(28, weight: .bold)).foregroundStyle(Brand.text)
            }
            Spacer()
            Text("GAMES")
                .font(Brand.mono(12, weight: .medium)).tracking(1.4)
                .foregroundStyle(Brand.text3)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(sideShortName(match.oppNames))
                    .font(.caption).foregroundStyle(Brand.text3).lineLimit(1)
                Text("\(match.oppGamesWon)")
                    .font(Brand.mono(28, weight: .bold)).foregroundStyle(Brand.text)
            }
        }
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Games: your side \(match.myGamesWon), opponents \(match.oppGamesWon)")
    }

    // MARK: - Scoreboard

    private var scoreboard: some View {
        HStack(spacing: 14) {
            scoreColumn(
                title: match.myNames,
                score: currentGame?.myScore ?? 0,
                isLeader: (currentGame?.myScore ?? 0) > (currentGame?.oppScore ?? 0),
                tint: Brand.live,
                increment: { adjust(mine: true, by: 1) },
                decrement: { adjust(mine: true, by: -1) })
            scoreColumn(
                title: match.oppNames,
                score: currentGame?.oppScore ?? 0,
                isLeader: (currentGame?.oppScore ?? 0) > (currentGame?.myScore ?? 0),
                tint: Brand.info,
                increment: { adjust(mine: false, by: 1) },
                decrement: { adjust(mine: false, by: -1) })
        }
        .overlay(alignment: .top) {
            if let winner = gameWinner {
                Text(winner == .me ? "Game — your side!" : "Game — opponents")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Capsule().fill(winner == .me ? Brand.live : Brand.info))
                    .offset(y: -14)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityHidden(true)
            }
        }
        .animation(reduceMotion ? nil : Brand.ease(0.25), value: gameWinner)
    }

    private func scoreColumn(title: String, score: Int, isLeader: Bool, tint: Color,
                             increment: @escaping () -> Void,
                             decrement: @escaping () -> Void) -> some View {
        VStack(spacing: 14) {
            Text(sideShortName(title))
                .font(.headline).foregroundStyle(Brand.text)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text("\(score)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isLeader ? tint : Brand.text)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            HStack(spacing: 10) {
                Button(action: decrement) {
                    Image(systemName: "minus")
                        .font(.title3.weight(.bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(GlassButtonStyle())
                .frame(width: 56)
                .disabled(score <= 0 || gameWinner != nil)
                .accessibilityLabel("Subtract a point for \(sideShortName(title))")

                Button(action: increment) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(InkButtonStyle())
                .frame(width: 56)
                .disabled(gameWinner != nil)
                .accessibilityLabel("Add a point for \(sideShortName(title))")
            }
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Brand.glassStroke.opacity(0.55), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(sideShortName(title)) score \(score)")
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            if gameWinner != nil {
                Button {
                    nextGame()
                } label: {
                    Label("Next game", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(InkButtonStyle())
            }
            Button {
                Haptics.tap()
                showFinishConfirm = true
            } label: {
                Label("Finish match", systemImage: "flag.checkered")
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(!canFinish)

            Text(canFinish
                 ? "Finish once a side leads in games."
                 : "Score a game to enable finishing.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func adjust(mine: Bool, by delta: Int) {
        guard let game = currentGame, gameWinner == nil else { return }
        if mine {
            game.myScore = max(0, game.myScore + delta)
        } else {
            game.oppScore = max(0, game.oppScore + delta)
        }
        if delta > 0 { Haptics.tap() } else { Haptics.selection() }

        // If this point won the game, record it and pulse a success haptic.
        if ScoreEngine.winner(myScore: game.myScore, oppScore: game.oppScore,
                              pointsToWin: match.pointsToWin, winByTwo: match.winByTwo) != nil {
            recomputeTally()
            Haptics.success()
        }
        try? context.save()
    }

    /// Recomputes the games-won tally from scratch over all decided games.
    private func recomputeTally() {
        var my = 0, opp = 0
        for g in match.orderedGames {
            if let w = ScoreEngine.winner(myScore: g.myScore, oppScore: g.oppScore,
                                          pointsToWin: match.pointsToWin, winByTwo: match.winByTwo) {
                if w == .me { my += 1 } else { opp += 1 }
            }
        }
        match.myGamesWon = my
        match.oppGamesWon = opp
    }

    private func nextGame() {
        let nextOrder = (match.games.map(\.order).max() ?? -1) + 1
        let game = GameScore(order: nextOrder)
        match.games.append(game)
        try? context.save()
        Haptics.tap()
    }

    private func finish() {
        // Drop a trailing empty/undecided game so saved games are all real.
        if let last = currentGame,
           ScoreEngine.winner(myScore: last.myScore, oppScore: last.oppScore,
                              pointsToWin: match.pointsToWin, winByTwo: match.winByTwo) == nil,
           match.games.count > 1 {
            match.games.removeAll { $0.id == last.id }
            context.delete(last)
        }
        recomputeTally()
        match.isComplete = true
        RatingEngine.apply(to: match)
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func abandon() {
        context.delete(match)
        try? context.save()
        dismiss()
    }

    private func sideShortName(_ full: String) -> String {
        // Use first names to keep the big board readable.
        full.split(separator: "&")
            .map { $0.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init) ?? "" }
            .joined(separator: " & ")
    }
}
