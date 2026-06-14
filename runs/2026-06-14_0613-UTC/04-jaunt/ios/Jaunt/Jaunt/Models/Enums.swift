import SwiftUI

// MARK: - Item / Expense category

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case food, sight, lodging, transport, activity, shopping, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .food: return "Food"
        case .sight: return "Sight"
        case .lodging: return "Lodging"
        case .transport: return "Transport"
        case .activity: return "Activity"
        case .shopping: return "Shopping"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .food: return "fork.knife"
        case .sight: return "camera"
        case .lodging: return "bed.double"
        case .transport: return "airplane"
        case .activity: return "figure.hiking"
        case .shopping: return "bag"
        case .other: return "mappin.and.ellipse"
        }
    }

    var hue: Double {
        switch self {
        case .food: return 0.06       // warm orange
        case .sight: return 0.55      // azure
        case .lodging: return 0.78    // violet
        case .transport: return 0.60  // blue
        case .activity: return 0.35   // green
        case .shopping: return 0.92   // pink
        case .other: return 0.0       // neutral red-grey
        }
    }

    var tint: Color {
        Color(hue: hue, saturation: 0.62, brightness: 0.72)
    }
}

// MARK: - Packing category

enum PackCategory: String, Codable, CaseIterable, Identifiable {
    case essentials, clothing, toiletries, electronics, documents, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .essentials: return "Essentials"
        case .clothing: return "Clothing"
        case .toiletries: return "Toiletries"
        case .electronics: return "Electronics"
        case .documents: return "Documents"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .essentials: return "star"
        case .clothing: return "tshirt"
        case .toiletries: return "drop"
        case .electronics: return "bolt"
        case .documents: return "doc.text"
        case .other: return "shippingbox"
        }
    }

    /// Stable display order.
    var order: Int {
        switch self {
        case .essentials: return 0
        case .documents: return 1
        case .clothing: return 2
        case .toiletries: return 3
        case .electronics: return 4
        case .other: return 5
        }
    }

    var tint: Color {
        switch self {
        case .essentials: return Color(hex: "E67E22")
        case .clothing: return Color(hex: "2E86C1")
        case .toiletries: return Color(hex: "16A085")
        case .electronics: return Color(hex: "8E44AD")
        case .documents: return Color(hex: "C0392B")
        case .other: return Color(hex: "7F8C8D")
        }
    }
}

// MARK: - Trip phase classification

enum TripPhase {
    case upcoming
    case inProgress
    case past

    var sectionTitle: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .inProgress: return "In progress"
        case .past: return "Past"
        }
    }

    var sortRank: Int {
        switch self {
        case .inProgress: return 0
        case .upcoming: return 1
        case .past: return 2
        }
    }
}
