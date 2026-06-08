import Foundation
import SwiftData

enum PackCategory: String, Codable, CaseIterable, Identifiable {
    case essentials, clothing, toiletries, electronics, documents, other
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .essentials:  return "star.fill"
        case .clothing:    return "tshirt.fill"
        case .toiletries:  return "drop.fill"
        case .electronics: return "bolt.fill"
        case .documents:   return "doc.text.fill"
        case .other:       return "shippingbox.fill"
        }
    }
}

@Model
final class PackingItem {
    var id: UUID
    var name: String
    var categoryRaw: String
    var quantity: Int
    var packed: Bool
    var order: Int
    var trip: Trip?

    var category: PackCategory {
        get { PackCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: PackCategory = .essentials,
        quantity: Int = 1,
        packed: Bool = false,
        order: Int = 0,
        trip: Trip? = nil
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.quantity = max(1, quantity)
        self.packed = packed
        self.order = order
        self.trip = trip
    }
}
