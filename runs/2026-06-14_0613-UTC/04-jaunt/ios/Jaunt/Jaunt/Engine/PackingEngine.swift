import Foundation

/// Pure packing math and starter templates.
enum PackingEngine {

    struct Progress: Equatable {
        var packed: Int
        var total: Int
        /// 0...1 fraction packed. 0 when nothing to pack.
        var fraction: Double {
            guard total > 0 else { return 0 }
            return Double(packed) / Double(total)
        }
        var isComplete: Bool { total > 0 && packed == total }
    }

    static func progress(for items: [PackItem]) -> Progress {
        Progress(packed: items.filter { $0.packed }.count, total: items.count)
    }

    static func progress(forCategory category: PackCategory, in items: [PackItem]) -> Progress {
        let scoped = items.filter { $0.category == category }
        return Progress(packed: scoped.filter { $0.packed }.count, total: scoped.count)
    }

    // MARK: Templates

    enum Template: String, CaseIterable, Identifiable {
        case beach = "Beach"
        case city = "City"
        case business = "Business"
        case camping = "Camping"
        case winter = "Winter"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .beach: return "beach.umbrella"
            case .city: return "building.2"
            case .business: return "briefcase"
            case .camping: return "tent"
            case .winter: return "snowflake"
            }
        }

        var subtitle: String {
            switch self {
            case .beach: return "Sun, sand & swim"
            case .city: return "Walk & explore"
            case .business: return "Meetings & travel"
            case .camping: return "Off the grid"
            case .winter: return "Cold-weather kit"
            }
        }
    }

    /// Seed PackItems for a template. Fresh instances each call (unpacked).
    static func seeds(for template: Template) -> [PackItem] {
        spec(for: template).map { PackItem(name: $0.0, category: $0.1, quantity: $0.2) }
    }

    private static func spec(for template: Template) -> [(String, PackCategory, Int)] {
        let common: [(String, PackCategory, Int)] = [
            ("Passport / ID", .documents, 1),
            ("Phone charger", .electronics, 1),
            ("Wallet & cards", .essentials, 1),
            ("Toothbrush", .toiletries, 1),
            ("Medications", .toiletries, 1)
        ]
        switch template {
        case .beach:
            return common + [
                ("Swimsuit", .clothing, 2),
                ("Sunscreen", .toiletries, 1),
                ("Sunglasses", .essentials, 1),
                ("Beach towel", .other, 1),
                ("Sandals", .clothing, 1),
                ("Hat", .clothing, 1)
            ]
        case .city:
            return common + [
                ("Comfortable shoes", .clothing, 1),
                ("Day backpack", .essentials, 1),
                ("Reusable water bottle", .other, 1),
                ("Light jacket", .clothing, 1),
                ("Power bank", .electronics, 1)
            ]
        case .business:
            return common + [
                ("Laptop & charger", .electronics, 1),
                ("Dress shirts", .clothing, 3),
                ("Blazer", .clothing, 1),
                ("Dress shoes", .clothing, 1),
                ("Notebook & pen", .other, 1),
                ("Business cards", .documents, 1)
            ]
        case .camping:
            return common + [
                ("Tent", .other, 1),
                ("Sleeping bag", .other, 1),
                ("Headlamp", .electronics, 1),
                ("Hiking boots", .clothing, 1),
                ("Water filter", .other, 1),
                ("First-aid kit", .essentials, 1)
            ]
        case .winter:
            return common + [
                ("Insulated jacket", .clothing, 1),
                ("Thermal base layers", .clothing, 2),
                ("Gloves", .clothing, 1),
                ("Beanie", .clothing, 1),
                ("Wool socks", .clothing, 3),
                ("Lip balm", .toiletries, 1)
            ]
        }
    }
}
