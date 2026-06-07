import Foundation
import SwiftData

/// Seeds a realistic record: three courses and a chronological set of rounds so
/// the handicap, trend, and stats screens are populated on first launch.
enum SampleData {

    /// Tiny deterministic PRNG so the seeded record is stable across launches.
    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        init(_ seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    static func seed(into context: ModelContext) {
        let pebble = Course(
            name: "Cypress Dunes",
            location: "Pacific Coast",
            holePars:        [4,5,4,3,4,4,3,5,4, 4,4,3,5,4,4,3,4,5],
            holeStrokeIndex: [7,3,11,17,1,13,15,5,9, 8,2,16,6,12,4,18,10,14]
        )
        pebble.tees = [
            Tee(name: "Blue", courseRating: 72.1, slopeRating: 129, yardage: 6840),
            Tee(name: "White", courseRating: 70.0, slopeRating: 124, yardage: 6320),
            Tee(name: "Gold", courseRating: 67.8, slopeRating: 118, yardage: 5740)
        ]

        let parkland = Course(
            name: "Hollow Oak",
            location: "Midlands",
            holePars:        [4,4,5,3,4,4,5,3,4, 4,3,4,4,5,3,4,4,5],
            holeStrokeIndex: [5,9,1,15,3,11,7,17,13, 6,18,2,10,4,16,8,14,12]
        )
        parkland.tees = [
            Tee(name: "Championship", courseRating: 73.4, slopeRating: 133, yardage: 7010),
            Tee(name: "Members", courseRating: 71.2, slopeRating: 126, yardage: 6480)
        ]

        let links = Course(
            name: "Salt Marsh Links",
            location: "North Shore",
            holePars:        [4,3,4,5,4,4,3,4,5, 4,4,3,4,5,4,3,4,4],
            holeStrokeIndex: [3,17,7,1,11,5,15,9,13, 4,8,18,2,6,12,16,10,14]
        )
        links.tees = [
            Tee(name: "Back", courseRating: 71.0, slopeRating: 122, yardage: 6610),
            Tee(name: "Forward", courseRating: 69.1, slopeRating: 115, yardage: 6050)
        ]

        context.insert(pebble)
        context.insert(parkland)
        context.insert(links)

        var rng = Seeded(42)
        let courses = [pebble, parkland, links]
        let cal = Calendar.current
        let today = Date()

        // 22 rounds over the last ~5 months, gently improving skill.
        for i in 0..<22 {
            let course = courses[i % courses.count]
            let tee = course.sortedTees[i % max(1, course.sortedTees.count)]
            let daysAgo = (21 - i) * 7 + Int.random(in: 0...3, using: &rng)
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            // skill: average over par drifts from ~+16 down to ~+9
            let skill = 16.0 - (Double(i) / 21.0) * 7.0

            let round = Round(date: date, courseName: course.name, teeName: tee.name,
                              courseRating: tee.courseRating, slopeRating: tee.slopeRating,
                              holePars: course.holePars, holeStrokeIndex: course.holeStrokeIndex,
                              course: course)
            fill(round, overParTarget: skill, rng: &rng)
            context.insert(round)
        }
        try? context.save()
    }

    /// Fills hole scores so the round lands near `overParTarget` strokes over par.
    private static func fill(_ round: Round, overParTarget: Double, rng: inout Seeded) {
        let perHole = overParTarget / Double(round.holeCount)
        for i in round.holePars.indices {
            let par = round.holePars[i]
            // Expected strokes over par on this hole, harder holes (low SI) cost more.
            let difficulty = 1.0 - (Double(round.holeStrokeIndex[i]) - 1.0) / Double(round.holeCount)
            var over = perHole * (0.6 + 0.8 * difficulty)
            // random scatter
            over += Double(Int.random(in: -1...1, using: &rng))
            var score = par + Int(over.rounded())
            score = max(par - 1, min(par + 5, score))   // keep sane
            round.holeScores[i] = score
            // putts: 2 typical, 1 on good holes
            round.holePutts[i] = score <= par ? Int.random(in: 1...2, using: &rng) : Int.random(in: 2...3, using: &rng)
            // GIR more likely when scoring well
            round.greenInRegulation[i] = score <= par && Bool.random(using: &rng)
            // fairway for par 4/5
            round.fairwayHit[i] = par >= 4 && (Int.random(in: 0...10, using: &rng) > 4)
        }
    }
}
