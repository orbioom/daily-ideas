import Foundation
import SwiftData

/// A recorded match — a best-of-N-legs game against an opponent.
@Model
final class Match {
    var date: Date
    var opponent: String
    var startScore: Int          // 301 / 501 / 701
    var bestOfLegs: Int          // e.g. 5 → first to 3
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \Leg.match) var legs: [Leg]

    init(date: Date = .now, opponent: String = "", startScore: Int = 501,
         bestOfLegs: Int = 5, notes: String = "") {
        self.date = date
        self.opponent = opponent
        self.startScore = startScore
        self.bestOfLegs = bestOfLegs
        self.notes = notes
        self.legs = []
    }

    var orderedLegs: [Leg] { legs.sorted { $0.index < $1.index } }
    var legsWon: Int { legs.filter { $0.didWin }.count }
    var legsLost: Int { legs.filter { !$0.didWin }.count }
    var legsToWin: Int { bestOfLegs / 2 + 1 }

    var didWin: Bool { legsWon > legsLost }
    var isDecided: Bool { legsWon >= legsToWin || legsLost >= legsToWin }

    /// Three-dart average across all of my legs in this match.
    var threeDartAverage: Double {
        let darts = legs.reduce(0) { $0 + $1.dartsThrown }
        guard darts > 0 else { return 0 }
        let points = legs.reduce(0) { $0 + $1.pointsScored }
        return Double(points) / Double(darts) * 3.0
    }

    /// Highest single-visit score logged across this match's legs.
    var highestVisit: Int { legs.map(\.highestScore).max() ?? 0 }

    /// Fewest darts used in a leg I won (best leg), or nil.
    var bestLegDarts: Int? {
        legs.filter { $0.didWin }.map(\.dartsThrown).min()
    }

    var doubleAttempts: Int { legs.reduce(0) { $0 + $1.doubleAttempts } }
    var doublesHit: Int { legs.filter { $0.didWin && $0.checkoutDouble > 0 }.count }
    var checkoutPercent: Double {
        guard doubleAttempts > 0 else { return 0 }
        return Double(doublesHit) / Double(doubleAttempts) * 100.0
    }
}

/// One leg within a match.
@Model
final class Leg {
    var index: Int
    var didWin: Bool
    var dartsThrown: Int          // total darts I threw this leg
    var pointsScored: Int         // points I scored (== startScore if I won)
    var checkoutDouble: Int       // the double I finished on (0 if I didn't win / unknown; 25 = bull)
    var doubleAttempts: Int       // darts thrown at a double this leg
    var highestScore: Int         // my best single visit this leg
    var match: Match?

    init(index: Int, didWin: Bool, dartsThrown: Int, pointsScored: Int,
         checkoutDouble: Int = 0, doubleAttempts: Int = 1, highestScore: Int = 0) {
        self.index = index
        self.didWin = didWin
        self.dartsThrown = dartsThrown
        self.pointsScored = pointsScored
        self.checkoutDouble = checkoutDouble
        self.doubleAttempts = doubleAttempts
        self.highestScore = highestScore
    }

    var average: Double {
        guard dartsThrown > 0 else { return 0 }
        return Double(pointsScored) / Double(dartsThrown) * 3.0
    }
}

/// A double-out practice session: throw at one target and log hits.
@Model
final class PracticeSession {
    var date: Date
    var targetValue: Int          // 1...20 for a double, 25 for the bull
    var darts: Int
    var hits: Int

    init(date: Date = .now, targetValue: Int = 16, darts: Int = 0, hits: Int = 0) {
        self.date = date
        self.targetValue = targetValue
        self.darts = darts
        self.hits = hits
    }

    var targetLabel: String { targetValue == 25 ? "Bull" : "D\(targetValue)" }
    var hitRate: Double {
        guard darts > 0 else { return 0 }
        return Double(hits) / Double(darts) * 100.0
    }
}
