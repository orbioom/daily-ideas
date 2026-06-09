import Foundation
import SwiftData

/// Optional sample circle so the home hub and insights are explorable at once.
enum SeedData {
    static func loadSample(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        struct P {
            let name: String; let rel: Relationship; let color: PersonColor
            let cadence: Int; let lastDays: Int; let met: String
            let birthday: (Int, Int, Int)?  // y, m, d
        }
        let people: [P] = [
            P(name: "Maya Chen", rel: .closeFriend, color: .rose, cadence: 21, lastDays: 26, met: "University roommates", birthday: (1992, 7, 14)),
            P(name: "Dad", rel: .family, color: .blue, cadence: 7, lastDays: 9, met: "", birthday: (1958, 11, 2)),
            P(name: "Sam Okoro", rel: .friend, color: .teal, cadence: 45, lastDays: 60, met: "Five-a-side football", birthday: (1990, 3, 28)),
            P(name: "Priya Patel", rel: .colleague, color: .indigo, cadence: 60, lastDays: 20, met: "Former teammate at work", birthday: nil),
            P(name: "Grandma Rose", rel: .family, color: .amber, cadence: 14, lastDays: 19, met: "", birthday: (1944, 6, 19)),
            P(name: "Tom Reyes", rel: .mentor, color: .slate, cadence: 90, lastDays: 40, met: "First manager", birthday: nil),
            P(name: "Lena", rel: .partner, color: .plum, cadence: 1, lastDays: 0, met: "A friend's birthday party", birthday: (1993, 9, 9))
        ]

        for p in people {
            let person = Person(name: p.name, relationship: p.rel, color: p.color,
                                cadenceDays: p.cadence, howWeMet: p.met)
            context.insert(person)
            // A handful of past interactions, most recent at lastDays.
            let types: [InteractionType] = [.call, .text, .met, .video, .social]
            for k in 0..<Int.random(in: 3...6) {
                let offset = p.lastDays + k * Int.random(in: 14...40)
                let date = cal.date(byAdding: .day, value: -offset, to: now) ?? now
                let inter = Interaction(date: date, type: types.randomElement() ?? .text,
                                        note: k == 0 ? "Caught up properly" : "")
                inter.person = person
                context.insert(inter)
            }
            if let b = p.birthday, let bd = cal.date(from: DateComponents(year: b.0, month: b.1, day: b.2)) {
                let d = ImportantDate(title: "Birthday", date: bd, kind: .birthday, recursAnnually: true)
                d.person = person
                context.insert(d)
            }
        }
        // An anniversary coming up for the partner.
        if let lena = (try? context.fetch(FetchDescriptor<Person>()))?.first(where: { $0.name == "Lena" }),
           let anniv = cal.date(from: DateComponents(year: 2019, month: 6, day: 21)) {
            let d = ImportantDate(title: "Anniversary", date: anniv, kind: .anniversary, recursAnnually: true)
            d.person = lena
            context.insert(d)
        }
        try? context.save()
    }
}
