import Foundation
import SwiftData

/// A group of related maintenance tasks (HVAC, Plumbing, Safety, …).
@Model
final class HomeSystem {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var order: Int

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceTask.system)
    var tasks: [MaintenanceTask]

    init(name: String,
         symbolName: String,
         order: Int) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.order = order
        self.tasks = []
    }
}

/// The canonical set of home systems Upkeep ships with.
enum SystemCatalog {
    /// (name, SF Symbol). Order is the array index.
    static let all: [(name: String, symbol: String)] = [
        ("HVAC", "fan"),
        ("Plumbing", "drop"),
        ("Exterior", "house"),
        ("Safety", "flame"),
        ("Appliances", "washer"),
        ("Lawn & Garden", "leaf"),
        ("Electrical", "bolt"),
        ("General", "wrench.and.screwdriver")
    ]

    static func symbol(for name: String) -> String {
        all.first { $0.name == name }?.symbol ?? "wrench.and.screwdriver"
    }
}
