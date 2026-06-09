import Foundation
import SwiftData

/// Seeds a believable traveler's passport on first launch so Passport and
/// Insights are never empty for a brand-new user: ~25 visited countries across
/// several continents (first-visit years 2008–2025, varied times-visited), a
/// couple "lived", ~11 wishlist, plus a few grouped Trips. Guarded so it runs
/// at most once.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<VisitMark>())) ?? []
        guard existing.isEmpty else { return }

        // MARK: Visited — (code, firstYear, timesVisited, favorite)
        let visited: [(String, Int, Int, Bool)] = [
            ("FR", 2009, 4, true),
            ("ES", 2010, 3, false),
            ("IT", 2011, 5, true),
            ("DE", 2012, 2, false),
            ("NL", 2013, 2, false),
            ("GB", 2008, 6, true),
            ("PT", 2015, 1, false),
            ("CH", 2014, 1, false),
            ("GR", 2016, 1, false),
            ("CZ", 2013, 1, false),
            ("HR", 2018, 1, false),
            ("IS", 2019, 1, true),
            ("US", 2010, 4, false),
            ("MX", 2017, 2, true),
            ("CA", 2012, 1, false),
            ("CR", 2019, 1, false),
            ("JP", 2018, 2, true),
            ("TH", 2016, 2, false),
            ("VN", 2017, 1, false),
            ("SG", 2018, 1, false),
            ("ID", 2019, 1, false),
            ("AU", 2022, 1, true),
            ("NZ", 2022, 1, false),
            ("MA", 2015, 1, false),
            ("ZA", 2023, 1, true),
            ("BR", 2024, 1, false),
            ("PE", 2024, 1, true),
            ("AR", 2025, 1, false)
        ]
        for (code, year, times, fav) in visited {
            let m = VisitMark(countryCode: code, status: .visited,
                              firstVisitYear: year, timesVisited: times, isFavorite: fav)
            m.createdAt = createdDate(forYear: year)
            m.updatedAt = m.createdAt
            context.insert(m)
        }

        // MARK: Lived
        let lived: [(String, Int)] = [("IE", 2011), ("KR", 2020)]
        for (code, year) in lived {
            let m = VisitMark(countryCode: code, status: .lived,
                              firstVisitYear: year, timesVisited: 1, isFavorite: code == "IE")
            m.createdAt = createdDate(forYear: year)
            m.updatedAt = m.createdAt
            context.insert(m)
        }

        // MARK: Transit (counted only if the user opts in)
        for code in ["AE", "QA"] {
            let m = VisitMark(countryCode: code, status: .transit,
                              firstVisitYear: 2018, timesVisited: 1)
            m.createdAt = createdDate(forYear: 2018)
            m.updatedAt = m.createdAt
            context.insert(m)
        }

        // MARK: Wishlist (all distinct from the visited/lived/transit codes above)
        for code in ["NO", "FI", "KE", "TZ", "NP", "IN", "CL", "EG", "JO", "TR", "KH"] {
            let m = VisitMark(countryCode: code, status: .wishlist, timesVisited: 0)
            context.insert(m)
        }

        // MARK: Trips
        seedTrips(context)

        try? context.save()
    }

    /// A createdAt anchored mid-year so the timeline/recency look organic.
    private static func createdDate(forYear year: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = 6
        comps.day = 15
        return Calendar.current.date(from: comps) ?? .now
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return Calendar.current.date(from: comps)
    }

    private static func seedTrips(_ context: ModelContext) {
        let trips: [(String, Int, Int, Int, Int, Int, Int, String, [String])] = [
            ("Grand European Loop", 2013, 6, 1, 2013, 7, 5, "First big backpacking summer.", ["FR", "DE", "CZ", "NL"]),
            ("Southeast Asia", 2017, 1, 8, 2017, 2, 2, "Street food and temples.", ["TH", "VN", "SG"]),
            ("Down Under", 2022, 11, 3, 2022, 12, 1, "Sydney to Queenstown.", ["AU", "NZ"]),
            ("South America", 2024, 9, 10, 2024, 9, 28, "Andes and Amazon.", ["BR", "PE"])
        ]
        for (title, sy, sm, sd, ey, em, ed, note, codes) in trips {
            let trip = Trip(title: title,
                            startDate: date(sy, sm, sd),
                            endDate: date(ey, em, ed),
                            note: note,
                            countryCodes: codes)
            context.insert(trip)
        }
    }
}
