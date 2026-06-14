import Foundation
import SwiftData

/// An anime or manga the user is tracking.
@Model
final class Title {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Stored as raw string for SwiftData stability; access via `kind`.
    var kindRaw: String
    /// Stored as raw string; access via `status`.
    var statusRaw: String
    var totalUnits: Int?        // episodes (anime) or chapters (manga); nil = unknown
    var progress: Int           // units done
    var score: Int              // 0...10, 0 = unrated
    var favorite: Bool
    /// Stored as raw string; access via `season`. Empty = none.
    var seasonRaw: String
    var seasonYear: Int?
    var studioOrAuthor: String
    var notes: String
    var coverHue: Double        // 0...1, deterministic gradient cover
    var addedAt: Date
    var startedAt: Date?
    var finishedAt: Date?
    var rewatchCount: Int

    @Relationship(deleteRule: .cascade, inverse: \WatchLog.title)
    var logs: [WatchLog] = []

    var genres: [Genre] = []

    init(name: String,
         kind: AnimeMediaKind,
         status: WatchStatus = .planning,
         totalUnits: Int? = nil,
         progress: Int = 0,
         score: Int = 0,
         favorite: Bool = false,
         season: AnimeSeason? = nil,
         seasonYear: Int? = nil,
         studioOrAuthor: String = "",
         notes: String = "",
         coverHue: Double? = nil,
         addedAt: Date = .now,
         startedAt: Date? = nil,
         finishedAt: Date? = nil,
         rewatchCount: Int = 0) {
        self.id = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.statusRaw = status.rawValue
        self.totalUnits = totalUnits.map { max(0, $0) }
        self.progress = max(0, progress)
        self.score = min(max(score, 0), 10)
        self.favorite = favorite
        self.seasonRaw = season?.rawValue ?? ""
        self.seasonYear = seasonYear
        self.studioOrAuthor = studioOrAuthor
        self.notes = notes
        self.coverHue = coverHue ?? Title.deterministicHue(for: name)
        self.addedAt = addedAt
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.rewatchCount = max(0, rewatchCount)
        self.logs = []
        self.genres = []
    }

    // MARK: Typed accessors

    var kind: AnimeMediaKind {
        get { AnimeMediaKind(rawValue: kindRaw) ?? .anime }
        set { kindRaw = newValue.rawValue }
    }

    var status: WatchStatus {
        get { WatchStatus(rawValue: statusRaw) ?? .planning }
        set { statusRaw = newValue.rawValue }
    }

    var season: AnimeSeason? {
        get { AnimeSeason(rawValue: seasonRaw) }
        set { seasonRaw = newValue?.rawValue ?? "" }
    }

    // MARK: Derived display

    /// Fraction complete in 0...1, guarded against nil/zero totals.
    var progressFraction: Double {
        guard let total = totalUnits, total > 0 else { return 0 }
        let clamped = min(max(progress, 0), total)
        return Double(clamped) / Double(total)
    }

    /// "7 / 12" or "7 / ?" when total is unknown.
    var progressLabel: String {
        if let total = totalUnits, total > 0 {
            return "\(min(progress, total)) / \(total)"
        }
        return "\(progress) / ?"
    }

    var statusLabel: String { status.label(for: kind) }

    var seasonLabel: String? {
        guard let season, let year = seasonYear else { return nil }
        return "\(season.rawValue) \(year)"
    }

    var isComplete: Bool {
        guard let total = totalUnits, total > 0 else { return status == .completed }
        return progress >= total
    }

    /// Deterministic 0...1 hue derived from the title name, so covers are stable.
    static func deterministicHue(for name: String) -> Double {
        var hash: UInt64 = 5381
        for scalar in name.unicodeScalars {
            hash = (hash &* 33) &+ UInt64(scalar.value)
        }
        return Double(hash % 1000) / 1000.0
    }
}
