import SwiftUI

/// The functional role an ingredient plays in a dough. Drives the baker's-percentage
/// engine: which ingredients count toward flour, water, levain, and salt totals.
enum Role: String, CaseIterable, Identifiable, Codable {
    case flour
    case water
    case levain   // starter / pre-ferment; contributes BOTH flour and water at its own hydration
    case salt
    case other    // oil, seeds, malt, sugar — counted in dough weight but not flour/water/salt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flour:  return "Flour"
        case .water:  return "Water"
        case .levain: return "Levain"
        case .salt:   return "Salt"
        case .other:  return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .flour:  return "square.grid.3x3.fill"
        case .water:  return "drop.fill"
        case .levain: return "leaf.fill"
        case .salt:   return "circle.grid.2x2.fill"
        case .other:  return "seal.fill"
        }
    }
}

/// A loose categorisation of a formula, for filtering and at-a-glance recognition.
enum Style: String, CaseIterable, Identifiable, Codable {
    case sourdough
    case baguette
    case focaccia
    case wholeGrain
    case enriched
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sourdough:  return "Sourdough"
        case .baguette:   return "Baguette"
        case .focaccia:   return "Focaccia"
        case .wholeGrain: return "Whole grain"
        case .enriched:   return "Enriched"
        case .other:      return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .sourdough:  return "circle.hexagongrid.fill"
        case .baguette:   return "fork.knife"
        case .focaccia:   return "square.fill"
        case .wholeGrain: return "leaf.fill"
        case .enriched:   return "birthday.cake.fill"
        case .other:      return "oval.fill"
        }
    }
}

/// A step in a bake timeline. `kind` gives a default icon and a sensible default duration
/// but every step carries its own planned duration in minutes.
enum StepKind: String, CaseIterable, Identifiable, Codable {
    case autolyse
    case mix
    case bulk
    case fold
    case preshape
    case shape
    case proof
    case coldProof
    case bake
    case cool
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .autolyse:  return "Autolyse"
        case .mix:       return "Mix"
        case .bulk:      return "Bulk ferment"
        case .fold:      return "Fold"
        case .preshape:  return "Pre-shape"
        case .shape:     return "Shape"
        case .proof:     return "Proof"
        case .coldProof: return "Cold proof"
        case .bake:      return "Bake"
        case .cool:      return "Cool"
        case .custom:    return "Step"
        }
    }

    var symbol: String {
        switch self {
        case .autolyse:  return "drop.triangle"
        case .mix:       return "hands.sparkles"
        case .bulk:      return "timer"
        case .fold:      return "arrow.triangle.2.circlepath"
        case .preshape:  return "circle.dashed"
        case .shape:     return "circle.circle"
        case .proof:     return "wind"
        case .coldProof: return "snowflake"
        case .bake:      return "flame.fill"
        case .cool:      return "thermometer.snowflake"
        case .custom:    return "circle"
        }
    }

    /// A reasonable default planned duration, in minutes.
    var defaultMinutes: Int {
        switch self {
        case .autolyse:  return 40
        case .mix:       return 15
        case .bulk:      return 240
        case .fold:      return 5
        case .preshape:  return 20
        case .shape:     return 10
        case .proof:     return 120
        case .coldProof: return 720
        case .bake:      return 45
        case .cool:      return 60
        case .custom:    return 30
        }
    }
}
