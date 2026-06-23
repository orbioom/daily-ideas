import Foundation
import SwiftData

@Model
final class Appliance {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var brand: String
    var modelNumber: String
    var serialNumber: String
    var purchaseDate: Date?
    var warrantyMonths: Int      // 0 means no/unknown warranty
    var note: String
    var createdAt: Date

    var room: Room?

    /// Maintenance tasks tied to this appliance. Nullify so tasks survive
    /// deletion of the equipment record.
    @Relationship(deleteRule: .nullify, inverse: \MaintenanceTask.appliance)
    var tasks: [MaintenanceTask]

    init(name: String,
         kind: ApplianceKind,
         brand: String = "",
         modelNumber: String = "",
         serialNumber: String = "",
         purchaseDate: Date? = nil,
         warrantyMonths: Int = 0,
         note: String = "",
         room: Room? = nil,
         createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.brand = brand
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.warrantyMonths = max(0, warrantyMonths)
        self.note = note
        self.room = room
        self.createdAt = createdAt
        self.tasks = []
    }

    var kind: ApplianceKind {
        get { ApplianceKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    /// Warranty expiry computed from purchase date + months. Nil if unknown.
    var warrantyExpiry: Date? {
        guard let purchaseDate, warrantyMonths > 0 else { return nil }
        return Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate)
    }
}

enum WarrantyStatus {
    case unknown
    case active(daysLeft: Int)
    case expiringSoon(daysLeft: Int)
    case expired

    var label: String {
        switch self {
        case .unknown: return "No warranty info"
        case .active(let d): return "Under warranty · \(d)d left"
        case .expiringSoon(let d): return "Expiring soon · \(d)d left"
        case .expired: return "Warranty expired"
        }
    }
}
