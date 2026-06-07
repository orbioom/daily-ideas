import Foundation

/// Derives the life list, year list, lifer flags, and aggregate stats from the
/// raw sighting record.
enum LifeListEngine {

    /// IDs of the "lifer" sighting for each species — the earliest observation.
    /// Ties on date are broken by the earliest-created (stable) sighting id.
    static func liferSightingIDs(sightings: [Sighting]) -> Set<UUID> {
        var earliest: [UUID: Sighting] = [:]   // speciesID -> earliest sighting
        for s in sightings {
            guard let sp = s.species?.id else { continue }
            if let cur = earliest[sp] {
                if s.date < cur.date { earliest[sp] = s }
            } else {
                earliest[sp] = s
            }
        }
        return Set(earliest.values.map(\.id))
    }

    /// Species observed at least once, in taxonomic checklist order.
    static func lifeList(species: [Species]) -> [Species] {
        species.filter { !$0.sightings.isEmpty }
            .sorted { $0.taxonOrder < $1.taxonOrder }
    }

    /// Species observed in the given calendar year.
    static func yearList(species: [Species], year: Int, calendar: Calendar = .current) -> [Species] {
        species.filter { sp in
            sp.sightings.contains { calendar.component(.year, from: $0.date) == year }
        }
        .sorted { $0.taxonOrder < $1.taxonOrder }
    }

    struct Stats {
        var lifeSpecies: Int = 0
        var totalSightings: Int = 0
        var totalIndividuals: Int = 0
        var lifersThisYear: Int = 0
        var yearSpecies: Int = 0
        var families: Int = 0
        var topSpecies: [(name: String, count: Int)] = []
        var byFamily: [(name: String, count: Int)] = []
        var byMonth: [Int]   // 12 entries: distinct-species count per month index 0..11
    }

    static func stats(species: [Species], sightings: [Sighting],
                      year: Int, calendar: Calendar = .current) -> Stats {
        let seen = species.filter { !$0.sightings.isEmpty }
        var s = Stats(byMonth: Array(repeating: 0, count: 12))
        s.lifeSpecies = seen.count
        s.totalSightings = sightings.count
        s.totalIndividuals = sightings.map(\.count).reduce(0, +)
        s.families = Set(seen.map(\.family)).count
        s.yearSpecies = yearList(species: species, year: year, calendar: calendar).count

        // lifers this year: species whose first sighting falls in `year`
        s.lifersThisYear = seen.filter {
            guard let f = $0.firstSeen else { return false }
            return calendar.component(.year, from: f) == year
        }.count

        // top species by sighting count
        s.topSpecies = seen
            .map { ($0.commonName, $0.sightingCount) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { (name: $0.0, count: $0.1) }

        // by family
        var fam: [String: Int] = [:]
        for sp in seen { fam[sp.family, default: 0] += 1 }
        s.byFamily = fam.sorted { $0.value > $1.value }.prefix(6).map { (name: $0.key, count: $0.value) }

        // by month: distinct species observed in each month (any year)
        for m in 0..<12 {
            let month = m + 1
            let distinct = Set(sightings
                .filter { calendar.component(.month, from: $0.date) == month }
                .compactMap { $0.species?.id })
            s.byMonth[m] = distinct.count
        }
        return s
    }
}
