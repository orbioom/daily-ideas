import Foundation

/// Pure, deterministic Elo-style rating update mapped onto a DUPR-like 2.0–6.0
/// scale. The flow:
///
/// 1. Each rating in [2.0, 6.0] is linearly mapped to an internal Elo number in
///    roughly [1000, 2000] (250 Elo points per rating point).
/// 2. A side's strength is the average Elo of its players.
/// 3. Expected score uses the logistic formula
///    `E = 1 / (1 + 10^((oppElo - myElo) / 400))`.
/// 4. Each player moves by `K * (actual - expected)`, where `actual` is 1 for a
///    win and 0 for a loss, then we map back to the rating scale and clamp.
///
/// `K` is modest so a single match nudges a rating rather than swinging it.
enum RatingEngine {

    /// Elo points per one point of rating (2.0–6.0 → 1000–2000).
    static let eloPerRating: Double = 250
    static let eloBase: Double = 1000
    static let ratingBase: Double = 2.0
    /// Update sensitivity. ~24 keeps moves to a few hundredths of a rating point.
    static let kFactor: Double = 24

    static func ratingToElo(_ rating: Double) -> Double {
        eloBase + (rating - ratingBase) * eloPerRating
    }

    static func eloToRating(_ elo: Double) -> Double {
        ratingBase + (elo - eloBase) / eloPerRating
    }

    /// Average internal Elo of a side. Empty sides fall back to the scale midpoint.
    static func sideElo(_ ratings: [Double]) -> Double {
        guard !ratings.isEmpty else { return ratingToElo(4.0) }
        let avg = ratings.reduce(0, +) / Double(ratings.count)
        return ratingToElo(avg)
    }

    /// Expected score (0…1) for my side against the opponent side.
    static func expectedScore(myRatings: [Double], oppRatings: [Double]) -> Double {
        let myElo = sideElo(myRatings)
        let oppElo = sideElo(oppRatings)
        return 1 / (1 + pow(10, (oppElo - myElo) / 400))
    }

    /// The signed rating delta a single player on `myRatings`'s side receives.
    /// `didWin` is from that side's perspective.
    static func ratingDelta(myRatings: [Double],
                            oppRatings: [Double],
                            didWin: Bool) -> Double {
        let expected = expectedScore(myRatings: myRatings, oppRatings: oppRatings)
        let actual = didWin ? 1.0 : 0.0
        let eloDelta = kFactor * (actual - expected)
        // Convert the Elo move into rating units.
        return eloDelta / eloPerRating
    }

    /// New, clamped rating for a player given the match outcome.
    static func updatedRating(current: Double,
                              myRatings: [Double],
                              oppRatings: [Double],
                              didWin: Bool) -> Double {
        let delta = ratingDelta(myRatings: myRatings, oppRatings: oppRatings, didWin: didWin)
        return Player.clampRating(current + delta)
    }

    /// Applies the rating update to every participant of a completed match,
    /// mutating each `Player.rating` in place. Safe to call once per finish.
    static func apply(to match: Match) {
        guard match.isComplete else { return }
        let myRatings = match.mySide.map(\.rating)
        let oppRatings = match.oppSide.map(\.rating)
        guard !myRatings.isEmpty, !oppRatings.isEmpty else { return }

        let myWon = match.didWin

        // Capture pre-match ratings so both sides update against the same baseline.
        for player in match.mySide {
            player.rating = updatedRating(current: player.rating,
                                          myRatings: myRatings,
                                          oppRatings: oppRatings,
                                          didWin: myWon)
        }
        for player in match.oppSide {
            player.rating = updatedRating(current: player.rating,
                                          myRatings: oppRatings,
                                          oppRatings: myRatings,
                                          didWin: !myWon)
        }
    }
}
