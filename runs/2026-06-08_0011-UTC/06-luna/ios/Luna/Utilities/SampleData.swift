import Foundation
import SwiftData

enum SampleData {
    /// Six recent cycles (~29-day average, 5-day periods) plus some symptom logs,
    /// so predictions and insights have real history.
    static func load(into context: ModelContext) {
        let cal = Calendar.current
        let cycleLengths = [28, 30, 29, 27, 30, 29] // most recent last-ish
        var start = cal.date(byAdding: .day, value: -(cycleLengths.reduce(0, +) + 4), to: .now) ?? .now
        start = cal.startOfDay(for: start)

        let symptomPools: [[String]] = [
            ["Cramps", "Fatigue"], ["Headache"], ["Bloating", "Cravings"],
            ["High energy"], ["Tender breasts"], ["Calm"]
        ]

        for (i, len) in cycleLengths.enumerated() {
            let periodLen = 4 + (i % 2) // 4 or 5
            let end = cal.date(byAdding: .day, value: periodLen - 1, to: start)
            context.insert(Period(startDate: start, endDate: end))

            // Flow logs across the period.
            for d in 0..<periodLen {
                if let day = cal.date(byAdding: .day, value: d, to: start) {
                    let flow: Flow = d == 0 ? .light : (d <= 2 ? .heavy : (d == periodLen - 1 ? .spotting : .medium))
                    context.insert(DayLog(date: day, flow: flow,
                                          symptoms: d == 1 ? symptomPools[i % symptomPools.count] : [],
                                          mood: 2 + (d % 3)))
                }
            }
            // A mid-cycle symptom note.
            if let mid = cal.date(byAdding: .day, value: periodLen + 8, to: start) {
                context.insert(DayLog(date: mid, flow: .none, symptoms: ["High energy"], mood: 4))
            }
            start = cal.date(byAdding: .day, value: len, to: start) ?? start
        }
        try? context.save()
    }
}
