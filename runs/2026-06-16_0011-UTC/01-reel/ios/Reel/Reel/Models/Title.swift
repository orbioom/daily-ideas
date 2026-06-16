import Foundation
import SwiftData

/// A tracked film or TV show. The central entity of the app.
@Model
final class Title {
    @Attribute(.unique) var id: UUID
    var name: String
    var year: Int
    /// Stored as raw string for SwiftData stability; access via `kind`.
    var kindRaw: String
    /// Genre names (matches `Genre.rawValue` where possible).
    var genresRaw: [String]
    var synopsis: String
    /// Per-episode runtime for shows; full runtime for films. Minutes.
    var runtimeMinutes: Int
    /// Director (film) or showrunner/creator (show).
    var creator: String
    /// Stored as raw string; access via `status`.
    var statusRaw: String
    /// 0...5 in half-star steps. nil = unrated.
    var rating: Double?
    var isFavorite: Bool
    /// Drives the generated poster gradient. Any Int.
    var colorSeed: Int
    var addedDate: Date

    // Show-specific progress (zero/ignored for films).
    var totalEpisodes: Int
    var watchedEpisodes: Int
    var totalSeasons: Int

    @Relationship(deleteRule: .cascade, inverse: \DiaryEntry.title)
    var entries: [DiaryEntry] = []

    @Relationship(inverse: \Tag.titles)
    var tags: [Tag] = []

    init(name: String,
         year: Int,
         kind: TitleKind,
         genres: [String] = [],
         synopsis: String = "",
         runtimeMinutes: Int = 0,
         creator: String = "",
         status: WatchStatus = .watchlist,
         rating: Double? = nil,
         isFavorite: Bool = false,
         colorSeed: Int = 0,
         addedDate: Date = .now,
         totalEpisodes: Int = 0,
         watchedEpisodes: Int = 0,
         totalSeasons: Int = 0) {
        self.id = UUID()
        self.name = name
        self.year = year
        self.kindRaw = kind.rawValue
        self.genresRaw = genres
        self.synopsis = synopsis
        self.runtimeMinutes = max(0, runtimeMinutes)
        self.creator = creator
        self.statusRaw = status.rawValue
        self.rating = rating
        self.isFavorite = isFavorite
        self.colorSeed = colorSeed
        self.addedDate = addedDate
        self.totalEpisodes = max(0, totalEpisodes)
        self.watchedEpisodes = max(0, watchedEpisodes)
        self.totalSeasons = max(0, totalSeasons)
        self.entries = []
        self.tags = []
    }

    var kind: TitleKind {
        get { TitleKind(rawValue: kindRaw) ?? .movie }
        set { kindRaw = newValue.rawValue }
    }

    var status: WatchStatus {
        get { WatchStatus(rawValue: statusRaw) ?? .watchlist }
        set { statusRaw = newValue.rawValue }
    }

    /// Resolved Genre values (drops anything unrecognized).
    var genres: [Genre] { genresRaw.compactMap { Genre.from($0) } }

    /// Two-letter initials for the generated poster (e.g. "BR" for Breaking Bad).
    var initials: String {
        let words = name
            .split(whereSeparator: { $0 == " " || $0 == ":" || $0 == "-" })
            .map(String.init)
            .filter { !$0.isEmpty }
        let letters = words.prefix(2).compactMap { $0.first }
        let result = String(letters).uppercased()
        if result.isEmpty {
            return name.first.map { String($0).uppercased() } ?? "?"
        }
        return result
    }

    /// Total minutes this Title contributes to "hours watched":
    /// films count full runtime once watched; shows count watchedEpisodes × runtime.
    var watchedMinutes: Int {
        if kind.isShow {
            return max(0, watchedEpisodes) * max(0, runtimeMinutes)
        }
        return status == .watched ? max(0, runtimeMinutes) : 0
    }

    /// Episode progress 0...1 (0 when no episode count known).
    var episodeProgress: Double {
        guard kind.isShow, totalEpisodes > 0 else { return 0 }
        return min(1, Double(watchedEpisodes) / Double(totalEpisodes))
    }

    /// The decade label for grouping, e.g. 1994 -> "1990s".
    var decadeLabel: String {
        let decade = (year / 10) * 10
        return "\(decade)s"
    }

    var runtimeLabel: String {
        guard runtimeMinutes > 0 else { return "—" }
        if kind.isShow { return "\(runtimeMinutes) min/ep" }
        let h = runtimeMinutes / 60
        let m = runtimeMinutes % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        return "\(m)m"
    }
}
