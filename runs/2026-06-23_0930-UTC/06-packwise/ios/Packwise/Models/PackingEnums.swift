import SwiftUI

/// The high-level kind of trip. Drives which base items the generator emits.
enum TripType: String, CaseIterable, Identifiable, Codable {
    case beach, business, hiking, city, ski

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beach: return "Beach"
        case .business: return "Business"
        case .hiking: return "Hiking"
        case .city: return "City Break"
        case .ski: return "Ski"
        }
    }

    var symbol: String {
        switch self {
        case .beach: return "beach.umbrella.fill"
        case .business: return "briefcase.fill"
        case .hiking: return "figure.hiking"
        case .city: return "building.2.fill"
        case .ski: return "snowflake"
        }
    }

    var tint: Color {
        switch self {
        case .beach: return Color(red: 0.96, green: 0.66, blue: 0.20)
        case .business: return Color(red: 0.30, green: 0.42, blue: 0.62)
        case .hiking: return Color(red: 0.32, green: 0.58, blue: 0.36)
        case .city: return Color(red: 0.55, green: 0.40, blue: 0.78)
        case .ski: return Color(red: 0.25, green: 0.62, blue: 0.80)
        }
    }

    var blurb: String {
        switch self {
        case .beach: return "Sun, sand and swimwear"
        case .business: return "Meetings, smart attire and tech"
        case .hiking: return "Trails, layers and trail gear"
        case .city: return "Sightseeing and comfy shoes"
        case .ski: return "Slopes, warmth and snow gear"
        }
    }
}

/// Optional activities the traveler tags on a trip. Each adds extra items.
enum Activity: String, CaseIterable, Identifiable, Codable {
    case swimming, running, photography, formalDinner, kids, work
    case beachDay, snorkeling, climbing, camping, rainExpected, coldWeather

    var id: String { rawValue }

    var title: String {
        switch self {
        case .swimming: return "Swimming"
        case .running: return "Running"
        case .photography: return "Photography"
        case .formalDinner: return "Formal Dinner"
        case .kids: return "Travelling with Kids"
        case .work: return "Remote Work"
        case .beachDay: return "Beach Day"
        case .snorkeling: return "Snorkeling"
        case .climbing: return "Climbing"
        case .camping: return "Camping"
        case .rainExpected: return "Rain Expected"
        case .coldWeather: return "Cold Weather"
        }
    }

    var symbol: String {
        switch self {
        case .swimming: return "figure.pool.swim"
        case .running: return "figure.run"
        case .photography: return "camera.fill"
        case .formalDinner: return "fork.knife"
        case .kids: return "figure.and.child.holdinghands"
        case .work: return "laptopcomputer"
        case .beachDay: return "sun.max.fill"
        case .snorkeling: return "water.waves"
        case .climbing: return "figure.climbing"
        case .camping: return "tent.fill"
        case .rainExpected: return "cloud.rain.fill"
        case .coldWeather: return "thermometer.snowflake"
        }
    }
}

/// Categories used to group items on the packing screen.
enum PackCategory: String, CaseIterable, Identifiable, Codable {
    case clothing, toiletries, electronics, documents, gear, misc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clothing: return "Clothing"
        case .toiletries: return "Toiletries"
        case .electronics: return "Electronics"
        case .documents: return "Documents"
        case .gear: return "Gear"
        case .misc: return "Essentials"
        }
    }

    var symbol: String {
        switch self {
        case .clothing: return "tshirt.fill"
        case .toiletries: return "drop.fill"
        case .electronics: return "bolt.fill"
        case .documents: return "doc.text.fill"
        case .gear: return "backpack.fill"
        case .misc: return "shippingbox.fill"
        }
    }

    var tint: Color {
        switch self {
        case .clothing: return Color(red: 0.36, green: 0.55, blue: 0.78)
        case .toiletries: return Color(red: 0.30, green: 0.68, blue: 0.70)
        case .electronics: return Color(red: 0.55, green: 0.40, blue: 0.78)
        case .documents: return Color(red: 0.80, green: 0.50, blue: 0.30)
        case .gear: return Color(red: 0.32, green: 0.58, blue: 0.42)
        case .misc: return Color(red: 0.60, green: 0.42, blue: 0.55)
        }
    }

    /// Stable sort order on the packing screen.
    var sortIndex: Int {
        switch self {
        case .documents: return 0
        case .clothing: return 1
        case .toiletries: return 2
        case .electronics: return 3
        case .gear: return 4
        case .misc: return 5
        }
    }
}
