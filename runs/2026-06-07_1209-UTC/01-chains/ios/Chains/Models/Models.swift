import Foundation
import SwiftData

/// A disc-golf course: a named layout that owns an ordered set of holes.
@Model
final class DiscCourse {
    var id: UUID = UUID()
    var name: String = ""
    var location: String = ""
    /// Scratch Scoring Average — the score a 1000-rated player is expected to
    /// shoot here. Drives the round-rating estimate. Defaults to par.
    var ssa: Double = 54
    /// Rating points lost per throw over SSA. ~10 on a typical course.
    var pointsPerThrow: Double = 10
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Hole.course)
    var holes: [Hole] = []

    init(name: String, location: String = "", ssa: Double = 54, pointsPerThrow: Double = 10) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.ssa = ssa
        self.pointsPerThrow = pointsPerThrow
        self.createdAt = Date()
    }

    var orderedHoles: [Hole] { holes.sorted { $0.number < $1.number } }
    var par: Int { holes.map { $0.par }.reduce(0, +) }
    var totalDistanceFeet: Int { holes.map { $0.distanceFeet }.reduce(0, +) }
    var holeCount: Int { holes.count }
}

/// A single hole on a course.
@Model
final class Hole {
    var id: UUID = UUID()
    var number: Int = 1
    var par: Int = 3
    var distanceFeet: Int = 0
    var course: DiscCourse?

    init(number: Int, par: Int = 3, distanceFeet: Int = 0) {
        self.id = UUID()
        self.number = number
        self.par = par
        self.distanceFeet = distanceFeet
    }
}

/// A played round: a dated scorecard against a course, owning per-hole scores.
@Model
final class Round {
    var id: UUID = UUID()
    var date: Date = Date()
    var courseName: String = ""
    /// Snapshot of the course SSA at play time so old ratings stay stable.
    var ssa: Double = 54
    var pointsPerThrow: Double = 10
    var weather: String = "Calm"
    var notes: String = ""
    var isComplete: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \HoleScore.round)
    var scores: [HoleScore] = []

    init(date: Date = Date(), courseName: String = "", ssa: Double = 54,
         pointsPerThrow: Double = 10, weather: String = "Calm") {
        self.id = UUID()
        self.date = date
        self.courseName = courseName
        self.ssa = ssa
        self.pointsPerThrow = pointsPerThrow
        self.weather = weather
    }

    var orderedScores: [HoleScore] { scores.sorted { $0.holeNumber < $1.holeNumber } }
    var totalStrokes: Int { scores.map { $0.strokes }.reduce(0, +) }
    var totalPar: Int { scores.map { $0.par }.reduce(0, +) }
    var relativeToPar: Int { totalStrokes - totalPar }
    var totalPutts: Int { scores.map { $0.putts }.reduce(0, +) }
    var totalPenalties: Int { scores.map { $0.penalties }.reduce(0, +) }
    var holesPlayed: Int { scores.filter { $0.strokes > 0 }.count }

    /// Count of scores in each category relative to that hole's par.
    func tally(_ kind: ScoreKind) -> Int {
        orderedScores.filter { ScoreKind.classify(strokes: $0.strokes, par: $0.par) == kind }.count
    }
}

/// One hole's result inside a round.
@Model
final class HoleScore {
    var id: UUID = UUID()
    var holeNumber: Int = 1
    var par: Int = 3
    var distanceFeet: Int = 0
    var strokes: Int = 0
    var putts: Int = 0
    var penalties: Int = 0
    var round: Round?

    init(holeNumber: Int, par: Int = 3, distanceFeet: Int = 0,
         strokes: Int = 0, putts: Int = 0, penalties: Int = 0) {
        self.id = UUID()
        self.holeNumber = holeNumber
        self.par = par
        self.distanceFeet = distanceFeet
        self.strokes = strokes
        self.putts = putts
        self.penalties = penalties
    }

    var relative: Int { strokes - par }
}

/// Score categories relative to par, in disc-golf vocabulary.
enum ScoreKind: String, CaseIterable {
    case ace = "Ace"
    case eagle = "Eagle"
    case birdie = "Birdie"
    case par = "Par"
    case bogey = "Bogey"
    case doubleBogey = "Double+"

    static func classify(strokes: Int, par: Int) -> ScoreKind {
        guard strokes > 0 else { return .par }
        if strokes == 1 { return .ace }
        let r = strokes - par
        switch r {
        case ..<(-1): return .eagle
        case -1: return .birdie
        case 0: return .par
        case 1: return .bogey
        default: return .doubleBogey
        }
    }
}
