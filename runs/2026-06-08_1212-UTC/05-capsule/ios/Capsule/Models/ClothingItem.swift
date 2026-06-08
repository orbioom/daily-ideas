import Foundation
import SwiftData

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case tops, bottoms, outerwear, dresses, shoes, bags, accessories, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .tops: return "Tops"
        case .bottoms: return "Bottoms"
        case .outerwear: return "Outerwear"
        case .dresses: return "Dresses"
        case .shoes: return "Shoes"
        case .bags: return "Bags"
        case .accessories: return "Accessories"
        case .other: return "Other"
        }
    }
    var symbol: String {
        switch self {
        case .tops: return "tshirt.fill"
        case .bottoms: return "rectangle.portrait.fill"
        case .outerwear: return "jacket.fill"
        case .dresses: return "figure.dress.line.vertical.figure"
        case .shoes: return "shoe.fill"
        case .bags: return "bag.fill"
        case .accessories: return "eyeglasses"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

enum Season: Int, CaseIterable, Identifiable {
    case spring = 0, summer, fall, winter
    var id: Int { rawValue }
    var label: String { ["Spring", "Summer", "Fall", "Winter"][rawValue] }
    var bit: Int { 1 << rawValue }
    var symbol: String { ["leaf.fill", "sun.max.fill", "wind", "snowflake"][rawValue] }
}

@Model
final class ClothingItem {
    var id: UUID
    var name: String
    var categoryRaw: String
    var colorHex: UInt32
    var colorName: String
    var brand: String
    var seasonsMask: Int        // bitmask of Season.bit, 0 = all seasons
    var cost: Double
    var purchaseDate: Date?
    var notes: String
    var archived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WearLog.item)
    var wearLogs: [WearLog] = []

    @Relationship(inverse: \Outfit.items)
    var outfits: [Outfit] = []

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: ItemCategory = .tops,
        colorHex: UInt32 = 0x9E5E7E,
        colorName: String = "",
        brand: String = "",
        seasonsMask: Int = 0,
        cost: Double = 0,
        purchaseDate: Date? = nil,
        notes: String = "",
        archived: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.colorHex = colorHex
        self.colorName = colorName
        self.brand = brand
        self.seasonsMask = seasonsMask
        self.cost = max(0, cost)
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.archived = archived
        self.createdAt = createdAt
    }

    var wearCount: Int { wearLogs.count }

    /// Cost per wear, or nil if no cost recorded.
    var costPerWear: Double? {
        guard cost > 0 else { return nil }
        return cost / Double(max(1, wearCount))
    }

    var lastWorn: Date? { wearLogs.map { $0.date }.max() }

    func seasons() -> [Season] {
        guard seasonsMask != 0 else { return Season.allCases }
        return Season.allCases.filter { seasonsMask & $0.bit != 0 }
    }
}
