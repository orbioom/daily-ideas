import Foundation
import SwiftData

/// A live show — the core record. Headliner + venue + date, plus the setlist, support acts,
/// genres, and the memory details you want to keep.
@Model
final class Concert {
    @Attribute(.unique) var id: UUID
    var headliner: String
    var date: Date
    var venueName: String
    var city: String
    var country: String
    var tourName: String

    /// Stored as raw string for SwiftData stability; access via `status`.
    var statusRaw: String
    /// Stored as raw string; access via `type`.
    var typeRaw: String

    /// 0...5 in half steps; nil when un-rated (e.g. wishlist).
    var rating: Double?
    /// Money as Decimal for exact arithmetic; formatted via CurrencyFormatter.
    var ticketPrice: Decimal
    var seatInfo: String
    var companions: String
    var notes: String
    /// Stable seed for the ticket-stub gradient.
    var colorSeed: Int
    var isFavorite: Bool
    var addedDate: Date

    @Relationship(deleteRule: .cascade, inverse: \SetlistSong.concert)
    var setlist: [SetlistSong] = []
    @Relationship(deleteRule: .cascade, inverse: \SupportAct.concert)
    var supportActs: [SupportAct] = []

    /// Many-to-many; the inverse is declared on `Genre`.
    var genres: [Genre] = []

    init(headliner: String,
         date: Date,
         venueName: String = "",
         city: String = "",
         country: String = "",
         tourName: String = "",
         status: ConcertStatus = .attended,
         type: ConcertType = .concert,
         rating: Double? = nil,
         ticketPrice: Decimal = 0,
         seatInfo: String = "",
         companions: String = "",
         notes: String = "",
         colorSeed: Int = 0,
         isFavorite: Bool = false,
         addedDate: Date = .now) {
        self.id = UUID()
        self.headliner = headliner
        self.date = date
        self.venueName = venueName
        self.city = city
        self.country = country
        self.tourName = tourName
        self.statusRaw = status.rawValue
        self.typeRaw = type.rawValue
        self.rating = rating
        self.ticketPrice = ticketPrice
        self.seatInfo = seatInfo
        self.companions = companions
        self.notes = notes
        self.colorSeed = colorSeed
        self.isFavorite = isFavorite
        self.addedDate = addedDate
    }

    var status: ConcertStatus {
        get { ConcertStatus(rawValue: statusRaw) ?? .attended }
        set { statusRaw = newValue.rawValue }
    }

    var type: ConcertType {
        get { ConcertType(rawValue: typeRaw) ?? .concert }
        set { typeRaw = newValue.rawValue }
    }

    // MARK: - Derived helpers (pure, guarded)

    /// Calendar year of the show.
    var year: Int { Calendar.current.component(.year, from: date) }

    /// "Venue · City" with empties dropped.
    var locationLine: String {
        let parts = [venueName, city].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return parts.joined(separator: " · ")
    }

    /// True when this is a future wishlist show worth counting down to.
    var isUpcoming: Bool {
        status == .wishlist && date > Date()
    }

    /// Whole days until the show (>= 0), or nil if not upcoming.
    var daysUntil: Int? {
        guard isUpcoming else { return nil }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: date)
        guard let days = cal.dateComponents([.day], from: start, to: target).day else { return nil }
        return max(days, 0)
    }

    /// Setlist sorted by remembered order, then encores last.
    var orderedSetlist: [SetlistSong] {
        setlist.sorted { lhs, rhs in
            if lhs.isEncore != rhs.isEncore { return !lhs.isEncore }
            return lhs.order < rhs.order
        }
    }

    /// Support acts sorted by bill order.
    var orderedSupportActs: [SupportAct] {
        supportActs.sorted { $0.order < $1.order }
    }

    var sortedGenres: [Genre] {
        genres.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
