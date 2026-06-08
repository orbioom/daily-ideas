import SwiftUI
import SwiftData

enum LightLevel: String, Codable, CaseIterable {
    case low, medium, bright, direct

    var label: String {
        switch self {
        case .low:    return "Low Light"
        case .medium: return "Medium Light"
        case .bright: return "Bright Indirect"
        case .direct: return "Direct Sun"
        }
    }

    var symbol: String {
        switch self {
        case .low:    return "moon.fill"
        case .medium: return "cloud.sun.fill"
        case .bright: return "sun.max.fill"
        case .direct: return "sun.horizon.fill"
        }
    }

    var color: Color {
        switch self {
        case .low:    return Brand.text3
        case .medium: return Brand.info
        case .bright: return Brand.warn
        case .direct: return Brand.danger
        }
    }
}

@Model
final class Plant {
    var id: UUID
    var nickname: String
    var species: String
    var symbol: String
    var colorHex: UInt32
    var light: LightLevel
    var wateringIntervalDays: Int
    var fertilizeIntervalDays: Int
    var lastWatered: Date?
    var lastFertilized: Date?
    var acquired: Date
    var potSize: String
    var notes: String
    var archived: Bool
    var order: Int

    @Relationship(deleteRule: .nullify)
    var room: Room?

    @Relationship(deleteRule: .cascade)
    var careLog: [CareEvent]

    init(
        id: UUID = UUID(),
        nickname: String,
        species: String,
        symbol: String = "leaf.fill",
        colorHex: UInt32 = 0x4FB98C,
        light: LightLevel = .medium,
        wateringIntervalDays: Int = 7,
        fertilizeIntervalDays: Int = 14,
        lastWatered: Date? = nil,
        lastFertilized: Date? = nil,
        acquired: Date = Date(),
        potSize: String = "",
        notes: String = "",
        archived: Bool = false,
        order: Int = 0,
        room: Room? = nil,
        careLog: [CareEvent] = []
    ) {
        self.id = id
        self.nickname = nickname
        self.species = species
        self.symbol = symbol
        self.colorHex = colorHex
        self.light = light
        self.wateringIntervalDays = wateringIntervalDays
        self.fertilizeIntervalDays = fertilizeIntervalDays
        self.lastWatered = lastWatered
        self.lastFertilized = lastFertilized
        self.acquired = acquired
        self.potSize = potSize
        self.notes = notes
        self.archived = archived
        self.order = order
        self.room = room
        self.careLog = careLog
    }
}
