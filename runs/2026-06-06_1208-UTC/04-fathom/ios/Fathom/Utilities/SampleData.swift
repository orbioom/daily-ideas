import Foundation
import SwiftData

/// Seeds a handful of sites and dives so the logbook and stats feel real.
enum SampleData {
    static func seed(into context: ModelContext) {
        let blue = DiveSite(name: "Blue Hole", location: "Dahab, Egypt")
        let reef = DiveSite(name: "Shark Reef", location: "Ras Mohammed")
        let wreck = DiveSite(name: "SS Thistlegorm", location: "Strait of Gubal")
        let kelp = DiveSite(name: "Breakwater", location: "Monterey, CA")
        for s in [blue, reef, wreck, kelp] { context.insert(s) }

        let cal = Calendar.current
        func d(_ daysAgo: Int) -> Date { cal.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date() }

        let dives: [(DiveSite, Double, Double, Int, Double, Int, Int, Int, DiveType, Int)] = [
            // site, max, avg, dur, temp, o2, startBar, endBar, type, rating
            (reef, 24, 14, 48, 26, 32, 210, 60, .boat, 5),
            (blue, 30, 18, 38, 25, 21, 220, 70, .shore, 4),
            (wreck, 28, 20, 42, 24, 32, 230, 80, .wreck, 5),
            (kelp, 16, 10, 55, 13, 21, 200, 40, .shore, 4),
            (reef, 22, 13, 50, 27, 32, 215, 55, .drift, 5),
            (blue, 18, 12, 60, 26, 36, 210, 90, .boat, 3),
            (kelp, 12, 8, 62, 14, 21, 205, 60, .shore, 4),
            (wreck, 26, 17, 45, 23, 32, 220, 75, .wreck, 5),
        ]
        for (i, item) in dives.enumerated() {
            let dive = Dive(date: d((dives.count - i) * 9), maxDepthM: item.1, durationMin: item.3)
            dive.avgDepthM = item.2
            dive.waterTempC = item.4
            dive.oxygenPercent = item.5
            dive.startPressureBar = item.6
            dive.endPressureBar = item.7
            dive.tankLitres = 12
            dive.type = item.8
            dive.rating = item.9
            dive.buddy = ["Sam", "Alex", "Mira", "Jo"][i % 4]
            dive.site = item.0
            item.0.dives.append(dive)
            context.insert(dive)
        }
        try? context.save()
    }
}
