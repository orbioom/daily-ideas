import Foundation
import SwiftData

/// The lifecycle of a gift idea, from a thought to wrapped-and-given. Anything
/// past `.idea` is considered "acquired" and counts toward spend & budgets.
enum GiftStatus: String, CaseIterable, Identifiable, Codable {
    case idea, bought, wrapped, given

    var id: String { rawValue }

    var label: String {
        switch self {
        case .idea:    return "Idea"
        case .bought:  return "Bought"
        case .wrapped: return "Wrapped"
        case .given:   return "Given"
        }
    }

    var symbol: String {
        switch self {
        case .idea:    return "lightbulb"
        case .bought:  return "bag"
        case .wrapped: return "gift"
        case .given:   return "checkmark.seal"
        }
    }

    /// Stable ordering for grouped lists and tallies.
    var order: Int {
        switch self {
        case .idea:    return 0
        case .bought:  return 1
        case .wrapped: return 2
        case .given:   return 3
        }
    }
}

/// A single gift idea, optionally tied to a person and an occasion. Price is
/// clamped non-negative. `isAcquired` drives spend and budget rollups.
@Model
final class Gift {
    var title: String
    var notes: String
    var price: Double
    var statusRaw: String
    var store: String
    var link: String
    var person: Person?
    var occasion: Occasion?
    var createdAt: Date

    init(title: String,
         notes: String = "",
         price: Double = 0,
         status: GiftStatus = .idea,
         store: String = "",
         link: String = "",
         person: Person? = nil,
         occasion: Occasion? = nil) {
        self.title = title
        self.notes = notes
        self.price = max(0, price)
        self.statusRaw = status.rawValue
        self.store = store
        self.link = link
        self.person = person
        self.occasion = occasion
        self.createdAt = .now
    }

    var status: GiftStatus {
        get { GiftStatus(rawValue: statusRaw) ?? .idea }
        set { statusRaw = newValue.rawValue }
    }

    /// Anything beyond an idea has been acquired and counts toward spend.
    var isAcquired: Bool { status != .idea }
}
