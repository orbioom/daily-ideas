import Foundation
import SwiftData

enum ItemStatus: String, CaseIterable, Codable, Identifiable {
    case sourced, listed, sold
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sourced: return "Death pile"
        case .listed: return "Listed"
        case .sold: return "Sold"
        }
    }
    var icon: String {
        switch self {
        case .sourced: return "shippingbox"
        case .listed: return "tag"
        case .sold: return "checkmark.seal"
        }
    }
}

enum ItemCategory: String, CaseIterable, Codable, Identifiable {
    case clothing, shoes, electronics, toys, media, home, collectibles, jewelry, sports, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .media: return "Books & media"
        case .home: return "Home goods"
        default: return rawValue.capitalized
        }
    }
}

enum SourceType: String, CaseIterable, Codable, Identifiable {
    case thrift, garage, estate, retail, online, freebie
    var id: String { rawValue }
    var label: String {
        switch self {
        case .thrift: return "Thrift store"
        case .garage: return "Garage sale"
        case .estate: return "Estate sale"
        case .retail: return "Retail arbitrage"
        case .online: return "Online"
        case .freebie: return "Free find"
        }
    }
}

enum Platform: String, CaseIterable, Codable, Identifiable {
    case ebay, poshmark, mercari, depop, facebook, etsy, inPerson
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ebay: return "eBay"
        case .poshmark: return "Poshmark"
        case .mercari: return "Mercari"
        case .depop: return "Depop"
        case .facebook: return "FB Marketplace"
        case .etsy: return "Etsy"
        case .inPerson: return "In person"
        }
    }
    /// Typical final-value fee, used to prefill (always editable per sale).
    var defaultFeeRate: Double {
        switch self {
        case .ebay: return 0.136
        case .poshmark: return 0.20
        case .mercari: return 0.129
        case .depop: return 0.139
        case .facebook: return 0.05
        case .etsy: return 0.095
        case .inPerson: return 0
        }
    }
}

@Model
final class Item {
    var title: String
    var categoryRaw: String
    var sourceRaw: String
    /// What you paid for it.
    var cost: Double
    var sourcedDate: Date
    var statusRaw: String
    var listPrice: Double
    var listedDate: Date?
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \Sale.item)
    var sale: Sale?

    init(title: String, category: ItemCategory, source: SourceType, cost: Double,
         sourcedDate: Date = Date(), status: ItemStatus = .sourced,
         listPrice: Double = 0, listedDate: Date? = nil, notes: String = "") {
        self.title = title
        self.categoryRaw = category.rawValue
        self.sourceRaw = source.rawValue
        self.cost = cost
        self.sourcedDate = sourcedDate
        self.statusRaw = status.rawValue
        self.listPrice = listPrice
        self.listedDate = listedDate
        self.notes = notes
    }

    var category: ItemCategory { ItemCategory(rawValue: categoryRaw) ?? .other }
    var source: SourceType { SourceType(rawValue: sourceRaw) ?? .thrift }
    var status: ItemStatus { ItemStatus(rawValue: statusRaw) ?? .sourced }
}

@Model
final class Sale {
    var soldPrice: Double
    var fees: Double
    var shipping: Double
    var soldDate: Date
    var platformRaw: String
    var item: Item?

    init(soldPrice: Double, fees: Double, shipping: Double,
         soldDate: Date = Date(), platform: Platform) {
        self.soldPrice = soldPrice
        self.fees = fees
        self.shipping = shipping
        self.soldDate = soldDate
        self.platformRaw = platform.rawValue
    }

    var platform: Platform { Platform(rawValue: platformRaw) ?? .ebay }
}
