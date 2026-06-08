import SwiftUI
import SwiftData

enum RSVP: String, CaseIterable, Identifiable, Codable {
    case pending, yes, no, maybe
    var id: String { rawValue }
    var title: String {
        switch self {
        case .pending: return "Pending"
        case .yes: return "Attending"
        case .no: return "Declined"
        case .maybe: return "Maybe"
        }
    }
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .yes: return "checkmark.circle.fill"
        case .no: return "xmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .pending: return Color(hex: 0x8B8FA3)
        case .yes: return Color(hex: 0x3E9E78)
        case .no: return Color(hex: 0xC0553E)
        case .maybe: return Color(hex: 0xC08A3E)
        }
    }
}

enum WeddingSide: String, CaseIterable, Identifiable, Codable {
    case partnerA, partnerB, both
    var id: String { rawValue }
    var title: String {
        switch self {
        case .partnerA: return "Side A"
        case .partnerB: return "Side B"
        case .both: return "Both"
        }
    }
}

enum MealChoice: String, CaseIterable, Identifiable, Codable {
    case none, chicken, beef, fish, vegetarian, vegan, kids
    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: return "—"
        case .chicken: return "Chicken"
        case .beef: return "Beef"
        case .fish: return "Fish"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .kids: return "Kids meal"
        }
    }
}

@Model
final class Guest {
    var name: String
    var sideRaw: String
    var rsvpRaw: String
    var partySize: Int          // total seats this guest entry represents (incl. +1s)
    var mealRaw: String
    var notes: String
    var createdAt: Date
    var table: SeatingTable?

    init(name: String,
         side: WeddingSide = .both,
         rsvp: RSVP = .pending,
         partySize: Int = 1,
         meal: MealChoice = .none,
         notes: String = "") {
        self.name = name
        self.sideRaw = side.rawValue
        self.rsvpRaw = rsvp.rawValue
        self.partySize = max(1, partySize)
        self.mealRaw = meal.rawValue
        self.notes = notes
        self.createdAt = .now
    }

    var side: WeddingSide {
        get { WeddingSide(rawValue: sideRaw) ?? .both }
        set { sideRaw = newValue.rawValue }
    }
    var rsvp: RSVP {
        get { RSVP(rawValue: rsvpRaw) ?? .pending }
        set { rsvpRaw = newValue.rawValue }
    }
    var meal: MealChoice {
        get { MealChoice(rawValue: mealRaw) ?? .none }
        set { mealRaw = newValue.rawValue }
    }
}

@Model
final class SeatingTable {
    var name: String
    var capacity: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Guest.table)
    var guests: [Guest]

    init(name: String, capacity: Int = 8) {
        self.name = name
        self.capacity = max(1, capacity)
        self.createdAt = .now
        self.guests = []
    }

    /// Seats used by attending/maybe guests assigned here.
    var seatsUsed: Int {
        guests.filter { $0.rsvp != .no }.reduce(0) { $0 + $1.partySize }
    }
    var isOver: Bool { seatsUsed > capacity }
}

enum BudgetCategory: String, CaseIterable, Identifiable, Codable {
    case venue, catering, photography, attire, flowers, music
    case stationery, rings, transport, decor, beauty, favors, cake, other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .venue: return "Venue"
        case .catering: return "Catering"
        case .photography: return "Photo & Video"
        case .attire: return "Attire"
        case .flowers: return "Flowers"
        case .music: return "Music"
        case .stationery: return "Stationery"
        case .rings: return "Rings"
        case .transport: return "Transport"
        case .decor: return "Decor"
        case .beauty: return "Hair & Beauty"
        case .favors: return "Favors"
        case .cake: return "Cake"
        case .other: return "Other"
        }
    }
    var icon: String {
        switch self {
        case .venue: return "building.columns"
        case .catering: return "fork.knife"
        case .photography: return "camera.fill"
        case .attire: return "tshirt.fill"
        case .flowers: return "leaf.fill"
        case .music: return "music.note"
        case .stationery: return "envelope.fill"
        case .rings: return "circle.circle.fill"
        case .transport: return "car.fill"
        case .decor: return "sparkles"
        case .beauty: return "scissors"
        case .favors: return "gift.fill"
        case .cake: return "birthday.cake.fill"
        case .other: return "square.grid.2x2"
        }
    }
    var color: Color {
        switch self {
        case .venue: return Color(hex: 0x8B6FB0)
        case .catering: return Color(hex: 0xC0553E)
        case .photography: return Color(hex: 0x4E6BA8)
        case .attire: return Color(hex: 0xB07A8C)
        case .flowers: return Color(hex: 0x3E9E78)
        case .music: return Color(hex: 0x5E63A6)
        case .stationery: return Color(hex: 0x3E8F9E)
        case .rings: return Color(hex: 0xC0A24E)
        case .transport: return Color(hex: 0x6E8FB0)
        case .decor: return Color(hex: 0x9E7BA8)
        case .beauty: return Color(hex: 0xC07AA0)
        case .favors: return Color(hex: 0xC08A3E)
        case .cake: return Color(hex: 0xC04E7A)
        case .other: return Color(hex: 0x6E7287)
        }
    }
}

@Model
final class BudgetLine {
    var title: String
    var categoryRaw: String
    var estimatedCost: Double
    var actualCost: Double
    var paidAmount: Double
    var vendor: String
    var dueDate: Date?
    var notes: String
    var createdAt: Date

    init(title: String,
         category: BudgetCategory = .other,
         estimatedCost: Double = 0,
         actualCost: Double = 0,
         paidAmount: Double = 0,
         vendor: String = "",
         dueDate: Date? = nil,
         notes: String = "") {
        self.title = title
        self.categoryRaw = category.rawValue
        self.estimatedCost = max(0, estimatedCost)
        self.actualCost = max(0, actualCost)
        self.paidAmount = max(0, paidAmount)
        self.vendor = vendor
        self.dueDate = dueDate
        self.notes = notes
        self.createdAt = .now
    }

    var category: BudgetCategory {
        get { BudgetCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// The cost to count: actual if entered, else the estimate.
    var effectiveCost: Double { actualCost > 0 ? actualCost : estimatedCost }
    var remainingToPay: Double { max(0, effectiveCost - paidAmount) }
    var isPaid: Bool { effectiveCost > 0 && paidAmount >= effectiveCost }
}

@Model
final class ChecklistTask {
    var title: String
    var isDone: Bool
    var dueDate: Date?
    var categoryRaw: String
    var notes: String
    var createdAt: Date

    init(title: String,
         dueDate: Date? = nil,
         category: BudgetCategory = .other,
         notes: String = "",
         isDone: Bool = false) {
        self.title = title
        self.dueDate = dueDate
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.isDone = isDone
        self.createdAt = .now
    }

    var category: BudgetCategory {
        get { BudgetCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
