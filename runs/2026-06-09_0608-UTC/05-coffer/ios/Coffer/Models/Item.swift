import Foundation
import SwiftData

/// A category an item belongs to. Backed by a raw string on the model so the
/// schema stays stable even if cases are reordered.
enum InventoryCategory: String, CaseIterable, Identifiable, Codable {
    case electronics, appliances, furniture, jewelry, tools
    case clothing, kitchen, sports, media, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .electronics: return "Electronics"
        case .appliances:  return "Appliances"
        case .furniture:   return "Furniture"
        case .jewelry:     return "Jewelry"
        case .tools:       return "Tools"
        case .clothing:    return "Clothing"
        case .kitchen:     return "Kitchen"
        case .sports:      return "Sports"
        case .media:       return "Media"
        case .other:       return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .electronics: return "tv.and.hifispeaker.fill"
        case .appliances:  return "washer.fill"
        case .furniture:   return "sofa.fill"
        case .jewelry:     return "diamond.fill"
        case .tools:       return "wrench.and.screwdriver.fill"
        case .clothing:    return "tshirt.fill"
        case .kitchen:     return "fork.knife"
        case .sports:      return "figure.run"
        case .media:       return "books.vertical.fill"
        case .other:       return "shippingbox.fill"
        }
    }
}

/// The state of an item's manufacturer warranty relative to "now".
enum WarrantyStatus {
    case none           // no warranty recorded
    case active         // covered, beyond the expiring-soon window
    case expiringSoon   // covered, but ending within the configured window
    case expired        // coverage has lapsed

    var label: String {
        switch self {
        case .none:         return "No warranty"
        case .active:       return "Active"
        case .expiringSoon: return "Expiring soon"
        case .expired:      return "Expired"
        }
    }
}

/// A single owned item in the inventory.
@Model
final class Item {
    var name: String
    var categoryRaw: String
    var brand: String
    var modelNumber: String
    var serial: String
    var purchaseDate: Date?
    var price: Double
    var warrantyMonths: Int   // 0 = no warranty
    var notes: String
    var room: Room?
    var createdAt: Date

    init(name: String,
         category: InventoryCategory = .other,
         brand: String = "",
         modelNumber: String = "",
         serial: String = "",
         purchaseDate: Date? = nil,
         price: Double = 0,
         warrantyMonths: Int = 0,
         notes: String = "",
         room: Room? = nil,
         createdAt: Date = .now) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.brand = brand
        self.modelNumber = modelNumber
        self.serial = serial
        self.purchaseDate = purchaseDate
        self.price = max(0, price)
        self.warrantyMonths = min(max(warrantyMonths, 0), 600)
        self.notes = notes
        self.room = room
        self.createdAt = createdAt
    }

    var category: InventoryCategory {
        get { InventoryCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// The date warranty coverage ends, or nil if there is no purchase date or
    /// no warranty. Uses guarded calendar math so it can never crash.
    var warrantyExpiry: Date? {
        guard warrantyMonths > 0, let start = purchaseDate else { return nil }
        return Calendar.current.date(byAdding: .month, value: warrantyMonths, to: start)
    }
}
