import SwiftUI
import SwiftData

enum CareType: String, Codable, CaseIterable {
    case water, fertilize, mist, repot, prune, note

    var label: String {
        switch self {
        case .water:     return "Watered"
        case .fertilize: return "Fertilized"
        case .mist:      return "Misted"
        case .repot:     return "Repotted"
        case .prune:     return "Pruned"
        case .note:      return "Note"
        }
    }

    var actionLabel: String {
        switch self {
        case .water:     return "Water"
        case .fertilize: return "Fertilize"
        case .mist:      return "Mist"
        case .repot:     return "Repot"
        case .prune:     return "Prune"
        case .note:      return "Add Note"
        }
    }

    var symbol: String {
        switch self {
        case .water:     return "drop.fill"
        case .fertilize: return "sparkles"
        case .mist:      return "humidity.fill"
        case .repot:     return "arrow.up.forward.circle.fill"
        case .prune:     return "scissors"
        case .note:      return "note.text"
        }
    }

    var color: Color {
        switch self {
        case .water:     return Brand.info
        case .fertilize: return Brand.magic
        case .mist:      return Brand.live
        case .repot:     return Brand.warn
        case .prune:     return Brand.text2
        case .note:      return Brand.text3
        }
    }
}

@Model
final class CareEvent {
    var id: UUID
    var date: Date
    var type: CareType
    var note: String

    @Relationship(deleteRule: .nullify)
    var plant: Plant?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: CareType,
        note: String = "",
        plant: Plant? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.note = note
        self.plant = plant
    }
}
