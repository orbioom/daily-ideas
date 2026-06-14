import Foundation
import SwiftData

/// A single record in the collection or on the wantlist.
@Model
final class Record {
    @Attribute(.unique) var id: UUID
    var title: String           // album title
    var artist: String
    var year: Int?
    /// Stored raw; access via `format`.
    var formatRaw: String
    /// Stored raw; access via `speed`.
    var speedRaw: String
    var genreRaw: String
    var label: String           // record label
    var catalogNo: String
    /// Stored raw; access via `mediaCondition`.
    var mediaConditionRaw: String
    /// Stored raw; access via `sleeveCondition`.
    var sleeveConditionRaw: String
    var pricePaid: Double
    var estValue: Double
    var vinylColor: String      // e.g. "Black", "Clear", "Splatter"
    /// Stored raw; access via `status`.
    var statusRaw: String
    var coverHue: Double        // 0...1 deterministic gradient seed
    var notes: String
    var addedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Track.record)
    var tracks: [Track]
    @Relationship(deleteRule: .cascade, inverse: \Spin.record)
    var spins: [Spin]

    init(title: String,
         artist: String,
         year: Int? = nil,
         format: Format = .lp,
         speed: Speed = .rpm33,
         genre: Genre = .other,
         label: String = "",
         catalogNo: String = "",
         mediaCondition: Grade = .nearMint,
         sleeveCondition: Grade = .nearMint,
         pricePaid: Double = 0,
         estValue: Double = 0,
         vinylColor: String = "Black",
         status: RecordStatus = .owned,
         coverHue: Double? = nil,
         notes: String = "",
         addedAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.year = year
        self.formatRaw = format.rawValue
        self.speedRaw = speed.rawValue
        self.genreRaw = genre.rawValue
        self.label = label
        self.catalogNo = catalogNo
        self.mediaConditionRaw = mediaCondition.rawValue
        self.sleeveConditionRaw = sleeveCondition.rawValue
        self.pricePaid = max(0, pricePaid)
        self.estValue = max(0, estValue)
        self.vinylColor = vinylColor
        self.statusRaw = status.rawValue
        self.coverHue = coverHue ?? genre.coverHueSeed
        self.notes = notes
        self.addedAt = addedAt
        self.tracks = []
        self.spins = []
    }

    // MARK: Enum accessors

    var format: Format {
        get { Format(rawValue: formatRaw) ?? .lp }
        set { formatRaw = newValue.rawValue }
    }

    var speed: Speed {
        get { Speed(rawValue: speedRaw) ?? .rpm33 }
        set { speedRaw = newValue.rawValue }
    }

    var genre: Genre {
        get { Genre(rawValue: genreRaw) ?? .other }
        set { genreRaw = newValue.rawValue }
    }

    var mediaCondition: Grade {
        get { Grade(rawValue: mediaConditionRaw) ?? .nearMint }
        set { mediaConditionRaw = newValue.rawValue }
    }

    var sleeveCondition: Grade {
        get { Grade(rawValue: sleeveConditionRaw) ?? .nearMint }
        set { sleeveConditionRaw = newValue.rawValue }
    }

    var status: RecordStatus {
        get { RecordStatus(rawValue: statusRaw) ?? .owned }
        set { statusRaw = newValue.rawValue }
    }

    // MARK: Derived helpers

    /// Decade derived from year, e.g. 1973 -> 1970. nil when year unknown.
    var decade: Int? {
        guard let y = year, y > 0 else { return nil }
        return (y / 10) * 10
    }

    /// Total tracklist runtime in seconds (0 for unknown durations).
    var totalRuntimeSeconds: Int {
        tracks.reduce(0) { $0 + max(0, $1.seconds) }
    }

    /// Most recent spin date, if any.
    var lastSpinDate: Date? {
        spins.map(\.date).max()
    }

    var spinCount: Int { spins.count }

    /// Display string for the year, or a dash.
    var yearLabel: String {
        guard let y = year, y > 0 else { return "—" }
        return String(y)
    }
}
