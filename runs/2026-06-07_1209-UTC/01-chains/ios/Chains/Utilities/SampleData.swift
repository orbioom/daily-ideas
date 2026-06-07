import Foundation
import SwiftData

/// Seeds realistic courses and a back-history of rounds so first launch shows a
/// living scorecard, rating trend, and trouble-hole insights immediately.
enum SampleData {
    static func seed(into context: ModelContext) {
        let pars1 = [3,3,4,3,3,3,4,3,3, 3,4,3,3,3,4,3,3,3]
        let dist1 = [285,310,520,240,330,295,640,260,275, 300,560,240,315,290,610,255,330,280]
        let oak = DiscCourse(name: "Oakridge Park", location: "Bend, OR", ssa: 50, pointsPerThrow: 10)
        for (i, p) in pars1.enumerated() {
            oak.holes.append(Hole(number: i + 1, par: p, distanceFeet: dist1[i]))
        }

        let pars2 = [3,4,3,3,4,3,3,3,4]
        let dist2 = [310,640,265,290,580,240,320,275,600]
        let creek = DiscCourse(name: "Cedar Creek", location: "Asheville, NC", ssa: 28, pointsPerThrow: 18)
        for (i, p) in pars2.enumerated() {
            creek.holes.append(Hole(number: i + 1, par: p, distanceFeet: dist2[i]))
        }

        context.insert(oak)
        context.insert(creek)

        // A back-catalogue of rounds with a gentle improvement trend.
        let cal = Calendar.current
        let oakRoundsOver = [12, 9, 10, 7, 8, 6, 5]   // strokes over par, improving
        for (idx, over) in oakRoundsOver.enumerated() {
            let daysAgo = (oakRoundsOver.count - idx) * 9
            guard let date = cal.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let round = Round(date: date, courseName: oak.name, ssa: oak.ssa,
                              pointsPerThrow: oak.pointsPerThrow, weather: idx % 2 == 0 ? "Calm" : "Breezy")
            round.isComplete = true
            var remaining = over
            for hole in oak.orderedHoles {
                // distribute the over-par strokes across harder (longer) holes
                var add = 0
                if remaining > 0 && hole.distanceFeet > 400 && Bool.random() { add = 1; remaining -= 1 }
                else if remaining > 0 && hole.par == 3 && hole.distanceFeet > 300 && Int.random(in: 0...2) == 0 { add = 1; remaining -= 1 }
                let strokes = max(1, hole.par + add - (add == 0 && Int.random(in: 0...4) == 0 ? 1 : 0))
                let s = HoleScore(holeNumber: hole.number, par: hole.par, distanceFeet: hole.distanceFeet,
                                  strokes: strokes, putts: min(strokes, Int.random(in: 1...2)), penalties: add)
                round.scores.append(s)
            }
            context.insert(round)
        }
    }
}
