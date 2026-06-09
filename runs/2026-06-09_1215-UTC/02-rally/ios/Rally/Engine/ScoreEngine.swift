import Foundation

/// Pure scoring rules for a single game. Knows nothing about SwiftData — it just
/// answers "has this game been won, and by whom?" given the target and win-by-two
/// rule. Used live by `LiveScoreView` and to validate stored games.
enum ScoreEngine {

    /// Which side, if any, has won a game at the given scores.
    enum Winner: Equatable {
        case me
        case opp
    }

    /// Returns the winning side, or `nil` if the game is still in progress.
    /// - A side must reach at least `pointsToWin`.
    /// - With `winByTwo`, they must also lead by two or more points.
    static func winner(myScore: Int,
                       oppScore: Int,
                       pointsToWin: Int,
                       winByTwo: Bool) -> Winner? {
        guard pointsToWin > 0 else { return nil }
        let lead = myScore - oppScore

        if myScore >= pointsToWin && (!winByTwo || lead >= 2) {
            return .me
        }
        if oppScore >= pointsToWin && (!winByTwo || -lead >= 2) {
            return .opp
        }
        return nil
    }

    /// Convenience: is the game decided at these scores?
    static func isGameWon(myScore: Int,
                          oppScore: Int,
                          pointsToWin: Int,
                          winByTwo: Bool) -> Bool {
        winner(myScore: myScore, oppScore: oppScore,
               pointsToWin: pointsToWin, winByTwo: winByTwo) != nil
    }

    /// Validates a stored game: scores non-negative and, if the match is finished,
    /// the game must actually be decided. Returns `nil` when valid, else a reason.
    static func validationError(myScore: Int,
                                oppScore: Int,
                                pointsToWin: Int,
                                winByTwo: Bool,
                                mustBeDecided: Bool) -> String? {
        if myScore < 0 || oppScore < 0 {
            return "Scores can't be negative."
        }
        if mustBeDecided && !isGameWon(myScore: myScore, oppScore: oppScore,
                                       pointsToWin: pointsToWin, winByTwo: winByTwo) {
            return "This game isn't finished yet."
        }
        return nil
    }
}
