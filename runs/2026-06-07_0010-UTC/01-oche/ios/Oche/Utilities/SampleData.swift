import Foundation
import SwiftData

/// Seeds a realistic first-run dataset so every screen has life on launch.
enum SampleData {
    static func seed(into context: ModelContext) {
        let opponents = ["Marek", "Priya", "Dad", "Club Night", "Online"]
        let cal = Calendar.current

        for m in 0..<6 {
            let match = Match(
                date: cal.date(byAdding: .day, value: -(m * 4 + 1), to: .now) ?? .now,
                opponent: opponents[m % opponents.count],
                startScore: 501,
                bestOfLegs: m % 2 == 0 ? 5 : 3,
                notes: m == 0 ? "Sharp on the doubles tonight." : ""
            )
            context.insert(match)

            let legCount = match.bestOfLegs == 5 ? 5 : 3
            var won = 0, lost = 0
            for i in 0..<legCount {
                let iWin = (m + i) % 2 == 0
                let darts = iWin ? Int.random(in: 15...24) : Int.random(in: 12...21)
                let leg = Leg(
                    index: i,
                    didWin: iWin,
                    dartsThrown: darts,
                    pointsScored: iWin ? 501 : Int.random(in: 280...460),
                    checkoutDouble: iWin ? [16, 20, 8, 10, 25].randomElement()! : 0,
                    doubleAttempts: Int.random(in: 1...3),
                    highestScore: [60, 81, 100, 121, 140, 180].randomElement()!
                )
                leg.match = match
                match.legs.append(leg)
                if iWin { won += 1 } else { lost += 1 }
                if won >= match.legsToWin || lost >= match.legsToWin { break }
            }
        }

        // Practice sessions across a spread of doubles.
        let targets = [16, 20, 8, 10, 4, 25, 12, 18]
        for (i, t) in targets.enumerated() {
            let darts = Int.random(in: 20...40)
            let rate = t == 25 ? 0.18 : Double.random(in: 0.25...0.55)
            let s = PracticeSession(
                date: cal.date(byAdding: .day, value: -(i + 1), to: .now) ?? .now,
                targetValue: t,
                darts: darts,
                hits: Int((Double(darts) * rate).rounded())
            )
            context.insert(s)
        }

        try? context.save()
    }
}
