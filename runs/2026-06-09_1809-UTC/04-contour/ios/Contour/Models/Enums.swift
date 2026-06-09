import Foundation
import SwiftUI

/// The camera angle a progress photo was taken from.
enum Pose: String, CaseIterable, Identifiable, Codable {
    case front, side, back

    var id: String { rawValue }

    var label: String {
        switch self {
        case .front: return "Front"
        case .side: return "Side"
        case .back: return "Back"
        }
    }

    var symbol: String {
        switch self {
        case .front: return "person.fill"
        case .side: return "person.fill.turn.right"
        case .back: return "person.fill.turn.down"
        }
    }
}

/// The dimensional category a metric is measured in.
enum UnitCategory: String, Codable {
    case mass, length, percent
}

/// A trackable body measurement. Values are stored canonical: kg for mass,
/// cm for length, % for body fat.
enum MetricType: String, CaseIterable, Identifiable, Codable {
    case weight, waist, chest, hips, arms, thighs, bodyFat, neck

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weight: return "Weight"
        case .waist: return "Waist"
        case .chest: return "Chest"
        case .hips: return "Hips"
        case .arms: return "Arms"
        case .thighs: return "Thighs"
        case .bodyFat: return "Body Fat"
        case .neck: return "Neck"
        }
    }

    var symbol: String {
        switch self {
        case .weight: return "scalemass"
        case .waist: return "figure"
        case .chest: return "lungs"
        case .hips: return "figure.walk"
        case .arms: return "figure.arms.open"
        case .thighs: return "figure.run"
        case .bodyFat: return "percent"
        case .neck: return "person.bust"
        }
    }

    var category: UnitCategory {
        switch self {
        case .weight: return .mass
        case .bodyFat: return .percent
        default: return .length
        }
    }
}
