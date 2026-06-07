import Foundation
import SwiftData

/// A bird in the catalog. Ships with a seeded set; users can add their own.
@Model
final class Species {
    var id: UUID = UUID()
    var commonName: String = ""
    var scientificName: String = ""
    var family: String = ""
    /// Taxonomic sort key (lower = earlier in checklist order).
    var taxonOrder: Int = 0
    var isCustom: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \Sighting.species)
    var sightings: [Sighting] = []

    init(commonName: String, scientificName: String, family: String,
         taxonOrder: Int, isCustom: Bool = false) {
        self.id = UUID()
        self.commonName = commonName
        self.scientificName = scientificName
        self.family = family
        self.taxonOrder = taxonOrder
        self.isCustom = isCustom
    }

    var sightingCount: Int { sightings.count }
    var firstSeen: Date? { sightings.map(\.date).min() }
    var lastSeen: Date? { sightings.map(\.date).max() }
    var totalIndividuals: Int { sightings.map(\.count).reduce(0, +) }
}

/// A single observation of a species.
@Model
final class Sighting {
    var id: UUID = UUID()
    var date: Date = Date()
    var location: String = ""
    var count: Int = 1
    var notes: String = ""
    var isFavorite: Bool = false
    var species: Species?
    var trip: Trip?

    init(date: Date, location: String, count: Int = 1, notes: String = "",
         species: Species? = nil, trip: Trip? = nil) {
        self.id = UUID()
        self.date = date
        self.location = location
        self.count = max(1, count)
        self.notes = notes
        self.species = species
        self.trip = trip
    }
}

/// A birding outing that groups sightings.
@Model
final class Trip {
    var id: UUID = UUID()
    var name: String = ""
    var date: Date = Date()
    var location: String = ""
    var notes: String = ""
    @Relationship(deleteRule: .nullify, inverse: \Sighting.trip)
    var sightings: [Sighting] = []

    init(name: String, date: Date, location: String = "", notes: String = "") {
        self.id = UUID()
        self.name = name
        self.date = date
        self.location = location
        self.notes = notes
    }

    var speciesCount: Int { Set(sightings.compactMap { $0.species?.id }).count }
    var individuals: Int { sightings.map(\.count).reduce(0, +) }
}
