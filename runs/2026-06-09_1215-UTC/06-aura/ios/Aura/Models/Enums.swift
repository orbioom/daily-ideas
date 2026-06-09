import Foundation
import SwiftUI

/// The clinical category of a headache episode.
enum HeadacheType: String, CaseIterable, Identifiable, Codable {
    case migraine, tension, cluster, sinus, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .migraine: return "Migraine"
        case .tension: return "Tension"
        case .cluster: return "Cluster"
        case .sinus: return "Sinus"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .migraine: return "bolt.fill"
        case .tension: return "circle.grid.cross"
        case .cluster: return "circle.dotted"
        case .sinus: return "nose"
        case .other: return "questionmark.circle"
        }
    }
}

/// Where the pain is felt.
enum HeadLocation: String, CaseIterable, Identifiable, Codable {
    case oneSided, bothSides, frontal, behindEye, backOfHead, unspecified

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneSided: return "One-sided"
        case .bothSides: return "Both sides"
        case .frontal: return "Frontal"
        case .behindEye: return "Behind eye"
        case .backOfHead: return "Back of head"
        case .unspecified: return "Unspecified"
        }
    }
}

/// Broad category used to group triggers in the catalog.
enum TriggerCategory: String, CaseIterable, Identifiable, Codable {
    case lifestyle, food, environment, hormonal, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lifestyle: return "Lifestyle"
        case .food: return "Food & drink"
        case .environment: return "Environment"
        case .hormonal: return "Hormonal"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .lifestyle: return "figure.walk"
        case .food: return "fork.knife"
        case .environment: return "cloud.sun"
        case .hormonal: return "drop"
        case .other: return "ellipsis.circle"
        }
    }
}

/// Whether a medication is taken to abort an attack or to prevent attacks.
enum MedType: String, CaseIterable, Identifiable, Codable {
    case acute, preventive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .acute: return "Acute"
        case .preventive: return "Preventive"
        }
    }
}

/// How much relief a medication gave during an attack.
enum Relief: String, CaseIterable, Identifiable, Codable {
    case none, some, lots, complete

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "No relief"
        case .some: return "Some relief"
        case .lots: return "Lots of relief"
        case .complete: return "Complete relief"
        }
    }

    /// A 0…3 score used to compute average effectiveness.
    var score: Int {
        switch self {
        case .none: return 0
        case .some: return 1
        case .lots: return 2
        case .complete: return 3
        }
    }

    var tint: Color {
        switch self {
        case .none: return Brand.danger
        case .some: return Brand.warn
        case .lots: return Brand.info
        case .complete: return Brand.live
        }
    }
}
