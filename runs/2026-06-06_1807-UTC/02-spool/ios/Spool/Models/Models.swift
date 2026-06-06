import Foundation
import SwiftData

/// A filament material. Carries the density used to convert mass <-> length.
enum Material: String, Codable, CaseIterable, Identifiable {
    case pla = "PLA", petg = "PETG", abs = "ABS", asa = "ASA"
    case tpu = "TPU", nylon = "Nylon", pc = "PC", hips = "HIPS", woodPLA = "Wood PLA"
    var id: String { rawValue }
    /// Density in g/cm³ (typical filament values).
    var density: Double {
        switch self {
        case .pla: return 1.24; case .petg: return 1.27; case .abs: return 1.04
        case .asa: return 1.07; case .tpu: return 1.21; case .nylon: return 1.14
        case .pc: return 1.20; case .hips: return 1.04; case .woodPLA: return 1.28
        }
    }
    /// Typical extrusion temperature range, for the detail card.
    var tempRange: String {
        switch self {
        case .pla: return "190–220 °C"; case .petg: return "230–250 °C"; case .abs: return "230–250 °C"
        case .asa: return "240–260 °C"; case .tpu: return "210–230 °C"; case .nylon: return "240–270 °C"
        case .pc: return "260–300 °C"; case .hips: return "230–245 °C"; case .woodPLA: return "190–220 °C"
        }
    }
}

/// Filament diameter standard.
enum Diameter: Double, Codable, CaseIterable, Identifiable {
    case mm175 = 1.75, mm285 = 2.85
    var id: Double { rawValue }
    var label: String { String(format: "%.2f mm", rawValue) }
}

/// A spool of filament in the user's inventory.
@Model
final class Spool {
    var brand: String
    var materialRaw: String
    var colorName: String
    var colorHex: String           // "RRGGBB"
    var diameterRaw: Double
    var netWeightG: Double         // total filament when full (grams)
    var remainingG: Double         // current remaining (grams)
    var pricePaid: Double
    var purchaseDate: Date
    var notes: String
    var archived: Bool

    @Relationship(deleteRule: .nullify, inverse: \PrintJob.spool)
    var prints: [PrintJob]

    init(brand: String, material: Material = .pla, colorName: String = "Natural",
         colorHex: String = "BFC4CC", diameter: Diameter = .mm175, netWeightG: Double = 1000,
         remainingG: Double? = nil, pricePaid: Double = 0, purchaseDate: Date = .now,
         notes: String = "", archived: Bool = false) {
        self.brand = brand
        self.materialRaw = material.rawValue
        self.colorName = colorName
        self.colorHex = colorHex
        self.diameterRaw = diameter.rawValue
        self.netWeightG = max(1, netWeightG)
        self.remainingG = remainingG ?? netWeightG
        self.pricePaid = pricePaid
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.archived = archived
        self.prints = []
    }

    var material: Material {
        get { Material(rawValue: materialRaw) ?? .pla }
        set { materialRaw = newValue.rawValue }
    }
    var diameter: Diameter {
        get { Diameter(rawValue: diameterRaw) ?? .mm175 }
        set { diameterRaw = newValue.rawValue }
    }

    var fractionRemaining: Double { netWeightG > 0 ? min(1, max(0, remainingG / netWeightG)) : 0 }
    var pricePerGram: Double { netWeightG > 0 ? pricePaid / netWeightG : 0 }
    /// Remaining filament length in meters (from remaining grams).
    var lengthRemainingM: Double {
        CostMath.lengthMeters(grams: remainingG, material: material, diameter: diameter)
    }
    var isLow: Bool { fractionRemaining <= 0.12 && remainingG > 0 }
    var isEmpty: Bool { remainingG <= 0.5 }
    var displayName: String { "\(brand) \(material.rawValue) · \(colorName)" }
}

/// A printer the user owns; its wattage feeds electricity cost.
@Model
final class Printer {
    var name: String
    var model: String
    var watts: Double
    var notes: String

    init(name: String, model: String = "", watts: Double = 120, notes: String = "") {
        self.name = name
        self.model = model
        self.watts = max(0, watts)
        self.notes = notes
    }
}

/// A logged print job. Consumes grams from a spool and computes its cost.
@Model
final class PrintJob {
    var name: String
    var date: Date
    var gramsUsed: Double
    var durationMinutes: Int
    var success: Bool
    var notes: String
    var spool: Spool?
    var printer: Printer?

    init(name: String, date: Date = .now, gramsUsed: Double = 0, durationMinutes: Int = 0,
         success: Bool = true, notes: String = "", spool: Spool? = nil, printer: Printer? = nil) {
        self.name = name
        self.date = date
        self.gramsUsed = max(0, gramsUsed)
        self.durationMinutes = max(0, durationMinutes)
        self.success = success
        self.notes = notes
        self.spool = spool
        self.printer = printer
    }

    var durationHours: Double { Double(durationMinutes) / 60.0 }
    var filamentCost: Double { (spool?.pricePerGram ?? 0) * gramsUsed }
    func electricityCost(kwhRate: Double) -> Double {
        guard let p = printer else { return 0 }
        return (p.watts / 1000.0) * durationHours * kwhRate
    }
    func totalCost(kwhRate: Double) -> Double { filamentCost + electricityCost(kwhRate: kwhRate) }
}
