import Foundation
import SwiftData

/// One focus block. A successful block plants a healthy tree; leaving the app
/// or giving up early leaves a withered one.
@Model
final class FocusSession {
    var id: UUID
    var date: Date
    var plannedSeconds: Double
    var completedSeconds: Double
    var success: Bool
    var tagName: String
    var species: String   // raw value of TreeSpecies

    init(id: UUID = UUID(),
         date: Date = .now,
         plannedSeconds: Double,
         completedSeconds: Double,
         success: Bool,
         tagName: String,
         species: String) {
        self.id = id
        self.date = date
        self.plannedSeconds = plannedSeconds
        self.completedSeconds = completedSeconds
        self.success = success
        self.tagName = tagName
        self.species = species
    }

    var minutes: Double { completedSeconds / 60 }
    var plannedMinutes: Int { Int((plannedSeconds / 60).rounded()) }
}

/// Tree planted depends on the length of the focus block — longer focus, bigger tree.
enum TreeSpecies: String, CaseIterable {
    case sprout, shrub, pine, oak, redwood

    static func forDuration(minutes: Double) -> TreeSpecies {
        switch minutes {
        case ..<15: return .sprout
        case 15..<30: return .shrub
        case 30..<50: return .pine
        case 50..<90: return .oak
        default: return .redwood
        }
    }

    var name: String {
        switch self {
        case .sprout: return "Sprout"
        case .shrub: return "Shrub"
        case .pine: return "Pine"
        case .oak: return "Oak"
        case .redwood: return "Redwood"
        }
    }
}
