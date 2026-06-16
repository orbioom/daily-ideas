import Foundation
import SwiftData

/// Seeds a default location, a few favourites, and sample observations once.
enum SeedData {
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        // Guard: only seed if there are no saved locations yet.
        let existing = (try? context.fetch(FetchDescriptor<SavedLocation>())) ?? []
        guard existing.isEmpty else { return }

        // --- Default + a spread of saved locations.
        let seedCityIDs = ["city.london", "city.newyork", "city.tokyo", "city.sydney", "city.capetown"]
        for cid in seedCityIDs {
            if let city = Gazetteer.byID[cid] {
                context.insert(SavedLocation(locationID: city.id, name: city.displayName,
                                             latitude: city.latitude, longitude: city.longitude,
                                             timeZoneID: city.timeZoneID))
            }
        }

        // --- A few favourites (Sirius, Vega, Jupiter, the Moon).
        let favs: [(String, String, SkyObjectKind)] = [
            ("star.53", "Sirius", .star),
            ("star.37", "Vega", .star),
            ("body.Jupiter", "Jupiter", .planet),
            ("body.Moon", "Moon", .moon)
        ]
        for (id, name, kind) in favs {
            context.insert(FavoriteObject(identifier: id, name: name, kindRaw: kind.rawValue))
        }

        // --- Sample observations.
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let obs: [(daysAgo: Int, object: String, note: String, place: String)] = [
            (2, "Saturn", "Caught the rings in the 6-inch — Cassini division just visible at 120×.", "London, UK"),
            (9, "Orion Nebula", "Naked-eye fuzz below the belt; stunning in binoculars from a dark site.", "London, UK"),
            (21, "Full Moon", "Rose blood-orange over the rooftops. Watched it climb for an hour.", "New York, USA")
        ]
        for o in obs {
            let date = cal.date(byAdding: .day, value: -o.daysAgo, to: now) ?? now
            context.insert(ObservationLog(date: date, objectName: o.object, note: o.note, locationName: o.place))
        }

        try? context.save()
    }
}
