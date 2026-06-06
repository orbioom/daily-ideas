import Foundation
import SwiftData

/// Seeds a realistic logbook so the app is never empty on first run.
enum SampleData {
    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        func day(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: .now) ?? .now }

        // A POTA activation at a park, fully activated.
        let pota = Activation(reference: "US-0001", title: "Acadia National Park",
                              kind: .pota, grid: "FN54", date: day(2),
                              notes: "Cool morning, 20m wide open to EU.")
        let potaContacts: [(String, Band, Mode, String, String)] = [
            ("K1ABC", .m20, .ssb, "FN42", "Boston, MA"),
            ("W4XYZ", .m20, .ssb, "EM73", "Atlanta, GA"),
            ("VE3DEF", .m20, .cw, "FN03", "Toronto, ON"),
            ("DL1GHI", .m20, .ft8, "JO31", "Köln, DE"),
            ("G0JKL", .m20, .ft8, "IO91", "London, UK"),
            ("EA5MNO", .m20, .ssb, "IM98", "Valencia, ES"),
            ("N7PQR", .m40, .ssb, "DN31", "Boise, ID"),
            ("KH6STU", .m20, .cw, "BL11", "Honolulu, HI"),
            ("JA1VWX", .m20, .ft8, "PM95", "Tokyo, JP"),
            ("VK2YZA", .m20, .ft8, "QF56", "Sydney, AU"),
            ("W9BCD", .m40, .ssb, "EN52", "Madison, WI"),
        ]
        for (i, c) in potaContacts.enumerated() {
            let q = QSO(callsign: c.0, dateTime: cal.date(byAdding: .minute, value: i * 4, to: day(2)) ?? day(2),
                        band: c.1, mode: c.2, theirGrid: c.3, theirQTH: c.4,
                        confirmed: i % 3 == 0, activation: pota)
            pota.qsos.append(q)
        }
        context.insert(pota)

        // A SOTA summit activation.
        let sota = Activation(reference: "W1/HA-001", title: "Mount Washington",
                              kind: .sota, grid: "FN44", date: day(9),
                              notes: "Windy. Quick 2m FM activation before the weather closed in.")
        for (i, c) in [("W1AA", Band.m2, Mode.fm, "FN42"), ("K1BB", .m2, .fm, "FN43"),
                       ("N1CC", .m40, .cw, "FN41"), ("W2DD", .m40, .cw, "FN20")].enumerated() {
            let q = QSO(callsign: c.0, dateTime: cal.date(byAdding: .minute, value: i * 6, to: day(9)) ?? day(9),
                        band: c.1, mode: c.2, theirGrid: c.3, confirmed: true, activation: sota)
            sota.qsos.append(q)
        }
        context.insert(sota)

        // A casual home session.
        let home = Activation(title: "Home Station", kind: .home, grid: "FN31", date: day(0),
                              notes: "Evening 40m ragchew.")
        for (i, c) in [("KD8EEE", Band.m40, Mode.ssb, "EN91", "Cleveland, OH"),
                       ("W5FFF", .m40, .ssb, "EM12", "Dallas, TX"),
                       ("VA7GGG", .m20, .ft8, "CN89", "Vancouver, BC")].enumerated() {
            let q = QSO(callsign: c.0, dateTime: cal.date(byAdding: .minute, value: i * 12, to: day(0)) ?? day(0),
                        band: c.1, mode: c.2, theirGrid: c.3, theirQTH: c.4, activation: home)
            home.qsos.append(q)
        }
        context.insert(home)

        try? context.save()
    }
}
