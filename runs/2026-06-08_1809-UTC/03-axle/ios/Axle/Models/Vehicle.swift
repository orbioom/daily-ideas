import Foundation
import SwiftData

/// A vehicle. Distances are stored canonically in kilometers and fuel volume
/// in liters; the UI converts to the user's chosen units at the edges.
@Model
final class Vehicle {
    var name: String
    var make: String
    var model: String
    var year: Int
    var plate: String
    var odometerKm: Double
    var fuelTypeRaw: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FuelEntry.vehicle)
    var fuelEntries: [FuelEntry]
    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.vehicle)
    var services: [ServiceRecord]
    @Relationship(deleteRule: .cascade, inverse: \ServiceReminder.vehicle)
    var reminders: [ServiceReminder]

    init(name: String,
         make: String = "",
         model: String = "",
         year: Int = Calendar.current.component(.year, from: .now),
         plate: String = "",
         odometerKm: Double = 0,
         fuelType: FuelType = .petrol) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.plate = plate
        self.odometerKm = max(0, odometerKm)
        self.fuelTypeRaw = fuelType.rawValue
        self.createdAt = .now
        self.fuelEntries = []
        self.services = []
        self.reminders = []
    }

    var fuelType: FuelType {
        get { FuelType(rawValue: fuelTypeRaw) ?? .petrol }
        set { fuelTypeRaw = newValue.rawValue }
    }

    var displaySubtitle: String {
        let parts = [year > 0 ? "\(year)" : "", make, model].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }
}

enum FuelType: String, CaseIterable, Identifiable, Codable {
    case petrol, diesel, hybrid, electric, lpg
    var id: String { rawValue }
    var title: String {
        switch self {
        case .petrol: return "Petrol"
        case .diesel: return "Diesel"
        case .hybrid: return "Hybrid"
        case .electric: return "Electric"
        case .lpg: return "LPG"
        }
    }
    var usesLiquidFuel: Bool { self != .electric }
}
