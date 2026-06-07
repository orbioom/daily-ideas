import Foundation
import SwiftData
import SwiftUI

/// Functional grouping of an electrical load, used for the energy breakdown donut.
enum LoadCategory: String, CaseIterable, Identifiable, Codable {
    case refrigeration
    case lighting
    case electronics
    case kitchen
    case water
    case climate
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .refrigeration: return "Refrigeration"
        case .lighting:      return "Lighting"
        case .electronics:   return "Electronics"
        case .kitchen:       return "Kitchen"
        case .water:         return "Water"
        case .climate:       return "Climate"
        case .other:         return "Other"
        }
    }

    var icon: String {
        switch self {
        case .refrigeration: return "refrigerator"
        case .lighting:      return "lightbulb"
        case .electronics:   return "laptopcomputer"
        case .kitchen:       return "cooktop"
        case .water:         return "drop"
        case .climate:       return "fan"
        case .other:         return "bolt"
        }
    }

    var tint: Color {
        switch self {
        case .refrigeration: return Brand.info
        case .lighting:      return Brand.warn
        case .electronics:   return Brand.magic
        case .kitchen:       return Brand.danger
        case .water:         return Brand.live
        case .climate:       return Color(hex: 0x8A6FD6)
        case .other:         return Brand.text3
        }
    }
}

@Model
final class Load {
    var id: UUID = UUID()
    var name: String = ""
    var watts: Double = 0
    var hoursPerDay: Double = 0
    var quantity: Int = 1
    var categoryRaw: String = LoadCategory.other.rawValue
    /// true means the load runs through the inverter (AC); false is direct DC.
    var isAC: Bool = false
    var system: PowerSystem?

    init(
        id: UUID = UUID(),
        name: String = "",
        watts: Double = 0,
        hoursPerDay: Double = 0,
        quantity: Int = 1,
        category: LoadCategory = .other,
        isAC: Bool = false,
        system: PowerSystem? = nil
    ) {
        self.id = id
        self.name = name
        self.watts = watts
        self.hoursPerDay = hoursPerDay
        self.quantity = quantity
        self.categoryRaw = category.rawValue
        self.isAC = isAC
        self.system = system
    }

    var category: LoadCategory {
        get { LoadCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Energy this load draws per day in watt-hours.
    var dailyWh: Double {
        watts * hoursPerDay * Double(max(quantity, 0))
    }
}
