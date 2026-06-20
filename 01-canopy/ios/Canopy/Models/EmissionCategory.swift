import SwiftUI

enum EmissionCategory: String, CaseIterable, Codable, Hashable {
    case transport = "Transport"
    case food = "Food"
    case energy = "Energy"
    case shopping = "Shopping"
    case waste = "Waste"

    var icon: String {
        switch self {
        case .transport: return "car.fill"
        case .food: return "fork.knife"
        case .energy: return "bolt.fill"
        case .shopping: return "bag.fill"
        case .waste: return "trash.fill"
        }
    }

    var color: String {
        switch self {
        case .transport: return "4A90D9"
        case .food: return "E8821A"
        case .energy: return "F5C518"
        case .shopping: return "9B59B6"
        case .waste: return "7F8C8D"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .transport: return Color(hex: "4A90D9")
        case .food: return Color(hex: "E8821A")
        case .energy: return Color(hex: "F5C518")
        case .shopping: return Color(hex: "9B59B6")
        case .waste: return Color(hex: "7F8C8D")
        }
    }
}
