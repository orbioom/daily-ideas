import Foundation
import SwiftUI
import SwiftData

/// Gear categories. The "big three" (shelter, sleep, pack) dominate base weight
/// and are where ultralight cuts pay off most.
enum GearCategory: String, CaseIterable, Identifiable {
    case shelter = "Shelter"
    case sleep = "Sleep"
    case pack = "Pack"
    case clothing = "Clothing"
    case cooking = "Cooking"
    case water = "Water"
    case electronics = "Electronics"
    case firstAid = "First Aid"
    case food = "Food"
    case other = "Other"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .shelter: return "tent"
        case .sleep: return "bed.double"
        case .pack: return "backpack"
        case .clothing: return "tshirt"
        case .cooking: return "flame"
        case .water: return "drop"
        case .electronics: return "bolt"
        case .firstAid: return "cross.case"
        case .food: return "fork.knife"
        case .other: return "shippingbox"
        }
    }
    var tint: Color {
        switch self {
        case .shelter: return Brand.info
        case .sleep: return Color(hex: 0x9A7BD0)
        case .pack: return Brand.warn
        case .clothing: return Brand.live
        case .cooking: return Color(hex: 0xD08A3E)
        case .water: return Color(hex: 0x4FB0C7)
        case .electronics: return Color(hex: 0x8B8FA3)
        case .firstAid: return Brand.danger
        case .food: return Color(hex: 0xC7A14F)
        case .other: return Brand.text3
        }
    }
    static let bigThree: Set<GearCategory> = [.shelter, .sleep, .pack]
}

/// A reusable piece of gear in your catalog. Weight is stored in grams.
@Model
final class GearItem {
    var id: UUID = UUID()
    var name: String = ""
    var brand: String = ""
    var categoryRaw: String = GearCategory.other.rawValue
    var weightGrams: Double = 0
    var isWorn: Bool = false        // worn/carried on body, not in the pack
    var isConsumable: Bool = false  // food, water, fuel — burned down on trail
    var notes: String = ""
    var createdAt: Date = Date()

    init(name: String, brand: String = "", category: GearCategory = .other,
         weightGrams: Double = 0, isWorn: Bool = false, isConsumable: Bool = false) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.categoryRaw = category.rawValue
        self.weightGrams = max(0, weightGrams)
        self.isWorn = isWorn
        self.isConsumable = isConsumable
        self.createdAt = Date()
    }

    var category: GearCategory {
        get { GearCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

/// A packing list for a trip, owning references to gear with quantities.
@Model
final class PackList {
    var id: UUID = UUID()
    var name: String = ""
    var trip: String = ""
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \PackEntry.list)
    var entries: [PackEntry] = []

    init(name: String, trip: String = "") {
        self.id = UUID()
        self.name = name
        self.trip = trip
        self.createdAt = Date()
    }
}

/// A gear item placed in a pack list, with a quantity and packed flag.
@Model
final class PackEntry {
    var id: UUID = UUID()
    var quantity: Int = 1
    var packed: Bool = false
    @Relationship(deleteRule: .nullify)
    var gear: GearItem?
    var list: PackList?

    init(gear: GearItem?, quantity: Int = 1) {
        self.id = UUID()
        self.gear = gear
        self.quantity = max(1, quantity)
    }

    var lineWeight: Double { (gear?.weightGrams ?? 0) * Double(max(1, quantity)) }
}
