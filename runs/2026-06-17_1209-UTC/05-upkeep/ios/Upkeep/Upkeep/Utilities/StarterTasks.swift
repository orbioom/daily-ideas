import Foundation

/// A blueprint for a starter task, independent of SwiftData.
struct StarterTaskBlueprint {
    let title: String
    let systemName: String
    let cadence: CadenceType
    let interval: Int
    let season: Season?
    let minutes: Int
    let cost: Double?
    let priority: Int
    let notes: String
}

/// The standard homeowner maintenance checklist Upkeep ships with.
enum StarterTasks {

    /// ≥15 real recurring home-maintenance tasks across the standard systems.
    static let blueprints: [StarterTaskBlueprint] = [
        StarterTaskBlueprint(title: "Replace furnace / HVAC filter",
                             systemName: "HVAC", cadence: .everyNMonths, interval: 3, season: nil,
                             minutes: 10, cost: 18, priority: 1,
                             notes: "Check sizing on the old filter before buying."),
        StarterTaskBlueprint(title: "Service HVAC — spring tune-up",
                             systemName: "HVAC", cadence: .seasonal, interval: 1, season: .spring,
                             minutes: 90, cost: 120, priority: 1,
                             notes: "Schedule the AC tune-up before cooling season."),
        StarterTaskBlueprint(title: "Service HVAC — fall tune-up",
                             systemName: "HVAC", cadence: .seasonal, interval: 1, season: .fall,
                             minutes: 90, cost: 120, priority: 1,
                             notes: "Heating tune-up before the cold sets in."),
        StarterTaskBlueprint(title: "Clean / replace humidifier pad",
                             systemName: "HVAC", cadence: .everyNYears, interval: 1, season: nil,
                             minutes: 20, cost: 25, priority: 3,
                             notes: "If you run a whole-home humidifier."),
        StarterTaskBlueprint(title: "Flush water heater",
                             systemName: "Plumbing", cadence: .everyNYears, interval: 1, season: nil,
                             minutes: 60, cost: 0, priority: 2,
                             notes: "Drain sediment to extend tank life."),
        StarterTaskBlueprint(title: "Test sump pump",
                             systemName: "Plumbing", cadence: .everyNMonths, interval: 6, season: nil,
                             minutes: 15, cost: 0, priority: 2,
                             notes: "Pour water into the pit and confirm it kicks on."),
        StarterTaskBlueprint(title: "Inspect under-sink supply lines",
                             systemName: "Plumbing", cadence: .everyNMonths, interval: 6, season: nil,
                             minutes: 15, cost: 0, priority: 2,
                             notes: "Look for corrosion, drips, or stiff hoses."),
        StarterTaskBlueprint(title: "Clean gutters — spring",
                             systemName: "Exterior", cadence: .seasonal, interval: 1, season: .spring,
                             minutes: 60, cost: 0, priority: 2,
                             notes: "Clear winter debris before spring rains."),
        StarterTaskBlueprint(title: "Clean gutters — fall",
                             systemName: "Exterior", cadence: .seasonal, interval: 1, season: .fall,
                             minutes: 75, cost: 0, priority: 1,
                             notes: "Clear leaves after they drop."),
        StarterTaskBlueprint(title: "Caulk & seal windows and doors",
                             systemName: "Exterior", cadence: .everyNYears, interval: 1, season: nil,
                             minutes: 120, cost: 30, priority: 2,
                             notes: "Re-seal gaps before winter to cut drafts."),
        StarterTaskBlueprint(title: "Inspect roof & flashing",
                             systemName: "Exterior", cadence: .everyNYears, interval: 1, season: nil,
                             minutes: 30, cost: 0, priority: 2,
                             notes: "Binoculars from the ground are fine."),
        StarterTaskBlueprint(title: "Pressure-wash deck / siding",
                             systemName: "Exterior", cadence: .seasonal, interval: 1, season: .summer,
                             minutes: 120, cost: 0, priority: 3,
                             notes: "Reseal the deck if water no longer beads."),
        StarterTaskBlueprint(title: "Replace smoke & CO detector batteries",
                             systemName: "Safety", cadence: .everyNMonths, interval: 6, season: nil,
                             minutes: 20, cost: 12, priority: 1,
                             notes: "Test every unit while you're at it."),
        StarterTaskBlueprint(title: "Test smoke & CO alarms",
                             systemName: "Safety", cadence: .everyNMonths, interval: 1, season: nil,
                             minutes: 10, cost: 0, priority: 1,
                             notes: "Press and hold the test button on each."),
        StarterTaskBlueprint(title: "Check fire extinguisher charge",
                             systemName: "Safety", cadence: .everyNMonths, interval: 6, season: nil,
                             minutes: 5, cost: 0, priority: 2,
                             notes: "Gauge should read in the green zone."),
        StarterTaskBlueprint(title: "Clean dryer vent & ductwork",
                             systemName: "Appliances", cadence: .everyNYears, interval: 1, season: nil,
                             minutes: 45, cost: 0, priority: 1,
                             notes: "Lint buildup is a leading fire cause."),
        StarterTaskBlueprint(title: "Clean refrigerator coils",
                             systemName: "Appliances", cadence: .everyNMonths, interval: 6, season: nil,
                             minutes: 20, cost: 0, priority: 3,
                             notes: "Improves efficiency and lifespan."),
        StarterTaskBlueprint(title: "Run dishwasher cleaning cycle",
                             systemName: "Appliances", cadence: .everyNMonths, interval: 3, season: nil,
                             minutes: 10, cost: 6, priority: 3,
                             notes: "Use a descaling cleaner."),
        StarterTaskBlueprint(title: "Winterize outdoor faucets & hoses",
                             systemName: "Lawn & Garden", cadence: .seasonal, interval: 1, season: .fall,
                             minutes: 30, cost: 0, priority: 1,
                             notes: "Drain and shut off to prevent burst pipes."),
        StarterTaskBlueprint(title: "Service lawn mower",
                             systemName: "Lawn & Garden", cadence: .seasonal, interval: 1, season: .spring,
                             minutes: 45, cost: 25, priority: 3,
                             notes: "Oil, blade sharpen, spark plug."),
        StarterTaskBlueprint(title: "Test GFCI outlets",
                             systemName: "Electrical", cadence: .everyNMonths, interval: 3, season: nil,
                             minutes: 10, cost: 0, priority: 2,
                             notes: "Press test then reset on each GFCI."),
        StarterTaskBlueprint(title: "Inspect electrical panel & label",
                             systemName: "Electrical", cadence: .everyNYears, interval: 1, season: nil,
                             minutes: 20, cost: 0, priority: 3,
                             notes: "Look for heat, rust, or loose breakers."),
        StarterTaskBlueprint(title: "Deep-clean garbage disposal",
                             systemName: "General", cadence: .everyNMonths, interval: 2, season: nil,
                             minutes: 10, cost: 0, priority: 3,
                             notes: "Ice cubes and citrus peels work well."),
        StarterTaskBlueprint(title: "Vacuum bathroom exhaust fans",
                             systemName: "General", cadence: .everyNMonths, interval: 6, season: nil,
                             minutes: 15, cost: 0, priority: 3,
                             notes: "Dust buildup hurts airflow.")
    ]
}
