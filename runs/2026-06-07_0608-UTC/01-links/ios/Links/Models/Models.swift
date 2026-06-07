import Foundation
import SwiftData

/// A golf course the player records rounds at. Holds the par and stroke-index
/// layout shared across its tees.
@Model
final class Course {
    var id: UUID = UUID()
    var name: String = ""
    var location: String = ""
    var createdAt: Date = Date()
    /// Par for each hole, in order. Length is 9 or 18.
    var holePars: [Int] = []
    /// Stroke-index (handicap difficulty rank, 1 = hardest) for each hole.
    var holeStrokeIndex: [Int] = []
    @Relationship(deleteRule: .cascade, inverse: \Tee.course)
    var tees: [Tee] = []

    init(name: String, location: String = "", holePars: [Int], holeStrokeIndex: [Int]) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.createdAt = Date()
        self.holePars = holePars
        self.holeStrokeIndex = holeStrokeIndex
    }

    var holeCount: Int { holePars.count }
    var par: Int { holePars.reduce(0, +) }
    var sortedTees: [Tee] { tees.sorted { $0.courseRating > $1.courseRating } }
}

/// A set of tee markers with their own rating and slope for a course.
@Model
final class Tee {
    var id: UUID = UUID()
    var name: String = ""
    var courseRating: Double = 72.0
    var slopeRating: Int = 113
    var yardage: Int = 0
    var course: Course?

    init(name: String, courseRating: Double, slopeRating: Int, yardage: Int = 0) {
        self.id = UUID()
        self.name = name
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.yardage = yardage
    }
}

/// A logged round. Stores a self-contained snapshot of the course/tee setup so
/// handicap math stays stable even if the source course is later edited.
@Model
final class Round {
    var id: UUID = UUID()
    var date: Date = Date()
    var courseName: String = ""
    var teeName: String = ""
    var courseRating: Double = 72.0
    var slopeRating: Int = 113
    var holePars: [Int] = []
    var holeStrokeIndex: [Int] = []
    var holeScores: [Int] = []
    var holePutts: [Int] = []
    var fairwayHit: [Bool] = []
    var greenInRegulation: [Bool] = []
    var notes: String = ""
    /// Optional reference back to the source course for navigation.
    var course: Course?

    init(date: Date, courseName: String, teeName: String,
         courseRating: Double, slopeRating: Int,
         holePars: [Int], holeStrokeIndex: [Int],
         course: Course? = nil) {
        self.id = UUID()
        self.date = date
        self.courseName = courseName
        self.teeName = teeName
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.holePars = holePars
        self.holeStrokeIndex = holeStrokeIndex
        let n = holePars.count
        self.holeScores = Array(repeating: 0, count: n)
        self.holePutts = Array(repeating: 0, count: n)
        self.fairwayHit = Array(repeating: false, count: n)
        self.greenInRegulation = Array(repeating: false, count: n)
        self.course = course
    }

    var holeCount: Int { holePars.count }
    var par: Int { holePars.reduce(0, +) }
    /// Gross total over holes that have been entered (score > 0).
    var totalScore: Int { holeScores.filter { $0 > 0 }.reduce(0, +) }
    var enteredHoleCount: Int { holeScores.filter { $0 > 0 }.count }
    var isComplete: Bool { enteredHoleCount == holeCount && holeCount > 0 }
    var toPar: Int { totalScore - parForEnteredHoles }
    var parForEnteredHoles: Int {
        zip(holePars, holeScores).filter { $0.1 > 0 }.map { $0.0 }.reduce(0, +)
    }
    /// Counts toward the WHS Handicap Index only when 18 holes are complete.
    var countsForHandicap: Bool { holeCount == 18 && isComplete }
    var totalPutts: Int { holePutts.filter { $0 > 0 }.reduce(0, +) }
    var fairwaysHitCount: Int {
        var c = 0
        for i in holePars.indices where holePars[i] >= 4 && holeScores[i] > 0 && fairwayHit[i] { c += 1 }
        return c
    }
    var fairwayOpportunities: Int {
        var c = 0
        for i in holePars.indices where holePars[i] >= 4 && holeScores[i] > 0 { c += 1 }
        return c
    }
    var girCount: Int {
        var c = 0
        for i in holePars.indices where holeScores[i] > 0 && greenInRegulation[i] { c += 1 }
        return c
    }
}
