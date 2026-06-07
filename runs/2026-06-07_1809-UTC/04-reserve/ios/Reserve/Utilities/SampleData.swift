import Foundation
import SwiftData

/// Seeds two believable systems on first launch so the dashboards look real.
enum SampleData {

    /// Insert sample systems if the store is empty. Safe to call repeatedly.
    static func seedIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<PowerSystem>())) ?? []
        guard existing.isEmpty else { return }
        for system in makeSystems() {
            context.insert(system)
        }
        try? context.save()
    }

    static func makeSystems() -> [PowerSystem] {
        [sprinterVan(), lakeCabin()]
    }

    // MARK: - Sprinter Van: LiFePO4 200Ah @12V, 400W solar, near break-even

    private static func sprinterVan() -> PowerSystem {
        let system = PowerSystem(
            name: "Sprinter Van",
            batteryCapacityAh: 200,
            systemVoltage: 12,
            chemistry: .lifepo4,
            dodOverride: 0,
            solarWatts: 400,
            peakSunHours: 4.5,
            solarEfficiency: 0.75,
            chargeEfficiency: 0.85,
            inverterWatts: 2000,
            createdAt: Date()
        )
        let names: [(String, Int)] = [
            ("12V Compressor Fridge", 1),
            ("MaxxFan Roof Vent", 1),
            ("LED Cabin Lights", 1),
            ("LED Strip / Mood", 1),
            ("Laptop Charge", 1),
            ("Phone Charge", 2),
            ("Starlink Mini", 1),
            ("Wi-Fi Router / Cell", 1),
            ("Water Pump", 1),
            ("Diesel Heater", 1),
            ("Induction Cooktop", 1)
        ]
        attach(names, to: system)
        return system
    }

    // MARK: - Lake Cabin: Flooded lead 400Ah @24V, 600W solar, comfortable surplus

    private static func lakeCabin() -> PowerSystem {
        let system = PowerSystem(
            name: "Lake Cabin",
            batteryCapacityAh: 400,
            systemVoltage: 24,
            chemistry: .floodedLead,
            dodOverride: 0,
            solarWatts: 600,
            peakSunHours: 4.0,
            solarEfficiency: 0.75,
            chargeEfficiency: 0.85,
            inverterWatts: 3000,
            createdAt: Date().addingTimeInterval(-86_400)
        )
        let names: [(String, Int)] = [
            ("Chest Freezer (12V)", 1),
            ("12V Compressor Fridge", 1),
            ("LED Cabin Lights", 2),
            ("Awning Light", 1),
            ("12V TV", 1),
            ("Wi-Fi Router / Cell", 1),
            ("Water Pump", 1),
            ("Diesel Water Heater", 1),
            ("Microwave", 1),
            ("Electric Kettle", 1),
            ("Power Tool Charger", 1)
        ]
        attach(names, to: system)
        return system
    }

    // MARK: - Helper

    private static func attach(_ entries: [(String, Int)], to system: PowerSystem) {
        for (name, qty) in entries {
            guard let template = ApplianceCatalog.appliance(name) else { continue }
            let load = template.makeLoad(quantity: qty)
            load.system = system
            system.loads.append(load)
        }
    }
}
