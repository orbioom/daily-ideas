import Foundation
import SwiftData

/// A fragrance in the user's collection / wishlist, with its note pyramid and wear log.
@Model
final class Fragrance {
    @Attribute(.unique) var id: UUID
    var name: String
    var house: String
    /// Stored as raw string; access via `concentration`.
    var concentrationRaw: String
    /// Comma-joined set of `Season` rawValues; access via `seasons`.
    var seasonsRaw: String
    /// Comma-joined set of `Occasion` rawValues; access via `occasions`.
    var occasionsRaw: String
    var sizeML: Double
    var pricePaid: Double
    var bottlesOwned: Int
    /// Stored as raw string; access via `status`.
    var statusRaw: String
    var rating: Int            // 0...5
    var longevityRating: Int   // 1...5
    var sillageRating: Int     // 1...5
    /// 0...1 hue used to render the juice-color swatch overlay.
    var colorHue: Double
    var notes: String
    var addedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \NotePlacement.fragrance)
    var placements: [NotePlacement] = []
    @Relationship(deleteRule: .cascade, inverse: \WearLog.fragrance)
    var wears: [WearLog] = []

    init(name: String,
         house: String,
         concentration: Concentration = .edp,
         seasons: Set<Season> = [],
         occasions: Set<Occasion> = [],
         sizeML: Double = 50,
         pricePaid: Double = 0,
         bottlesOwned: Int = 1,
         status: BottleStatus = .owned,
         rating: Int = 0,
         longevityRating: Int = 3,
         sillageRating: Int = 3,
         colorHue: Double = 0.12,
         notes: String = "",
         addedAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.house = house
        self.concentrationRaw = concentration.rawValue
        self.seasonsRaw = Fragrance.encode(seasons.map(\.rawValue))
        self.occasionsRaw = Fragrance.encode(occasions.map(\.rawValue))
        self.sizeML = max(0, sizeML)
        self.pricePaid = max(0, pricePaid)
        self.bottlesOwned = max(0, bottlesOwned)
        self.statusRaw = status.rawValue
        self.rating = min(max(rating, 0), 5)
        self.longevityRating = min(max(longevityRating, 1), 5)
        self.sillageRating = min(max(sillageRating, 1), 5)
        self.colorHue = min(max(colorHue, 0), 1)
        self.notes = notes
        self.addedAt = addedAt
    }

    // MARK: Enum accessors

    var concentration: Concentration {
        get { Concentration(rawValue: concentrationRaw) ?? .edp }
        set { concentrationRaw = newValue.rawValue }
    }

    var status: BottleStatus {
        get { BottleStatus(rawValue: statusRaw) ?? .owned }
        set { statusRaw = newValue.rawValue }
    }

    var seasons: Set<Season> {
        get { Set(Fragrance.decode(seasonsRaw).compactMap { Season(rawValue: $0) }) }
        set { seasonsRaw = Fragrance.encode(newValue.map(\.rawValue)) }
    }

    var occasions: Set<Occasion> {
        get { Set(Fragrance.decode(occasionsRaw).compactMap { Occasion(rawValue: $0) }) }
        set { occasionsRaw = Fragrance.encode(newValue.map(\.rawValue)) }
    }

    // MARK: Derived

    /// Times this fragrance has been worn.
    var timesWorn: Int { wears.count }

    /// Most recent wear date, if any.
    var lastWorn: Date? { wears.map(\.date).max() }

    /// Cost per wear in currency units (guards division by zero).
    var costPerWear: Double {
        pricePaid / Double(max(timesWorn, 1))
    }

    /// Notes in a given pyramid slot, ordered.
    func orderedNotes(in slot: NoteSlot) -> [NotePlacement] {
        placements.filter { $0.slot == slot }.sorted { $0.order < $1.order }
    }

    /// All note families present, deduplicated.
    var families: [NoteFamily] {
        var seen: [NoteFamily] = []
        for p in placements.sorted(by: { $0.order < $1.order }) where !seen.contains(p.family) {
            seen.append(p.family)
        }
        return seen
    }

    /// The dominant family — used for the swatch gradient and grouping.
    var primaryFamily: NoteFamily {
        var counts: [NoteFamily: Int] = [:]
        for p in placements { counts[p.family, default: 0] += 1 }
        return counts.max { $0.value < $1.value }?.key ?? families.first ?? .floral
    }

    // MARK: CSV helpers

    private static func encode(_ values: [String]) -> String {
        values.sorted().joined(separator: ",")
    }

    private static func decode(_ raw: String) -> [String] {
        raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
