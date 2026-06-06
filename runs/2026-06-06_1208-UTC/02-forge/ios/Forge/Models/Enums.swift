import SwiftUI

/// Weight units. Internally Forge stores every weight in kilograms; this
/// converts to and from whatever the lifter prefers to see and type.
enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var label: String { self == .kg ? "Kilograms (kg)" : "Pounds (lb)" }
    var short: String { rawValue }

    func fromKg(_ kg: Double) -> Double { self == .kg ? kg : kg * 2.2046226218 }
    func toKg(_ value: Double) -> Double { self == .kg ? value : value / 2.2046226218 }

    /// A sensible default barbell weight in this unit.
    var defaultBar: Double { self == .kg ? 20 : 45 }
    /// Standard plate sizes available in this unit (per plate, one side).
    var standardPlates: [Double] {
        self == .kg ? [25, 20, 15, 10, 5, 2.5, 1.25] : [45, 35, 25, 10, 5, 2.5]
    }
}

/// Movement grouping for exercises.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case push, pull, legs, core, olympic, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .core: return "Core"
        case .olympic: return "Olympic"
        case .other: return "Other"
        }
    }
    var symbol: String {
        switch self {
        case .push: return "arrow.up.circle"
        case .pull: return "arrow.down.circle"
        case .legs: return "figure.walk"
        case .core: return "circle.grid.cross"
        case .olympic: return "bolt.circle"
        case .other: return "dumbbell"
        }
    }
}

/// One-rep-max estimation formulas. Both are standard in the lifting literature.
enum OneRepMaxFormula: String, CaseIterable, Identifiable {
    case epley, brzycki
    var id: String { rawValue }
    var label: String { self == .epley ? "Epley" : "Brzycki" }
}
