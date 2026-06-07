import Foundation

/// The built-in catalog of real-shape model-rocket motors. These figures are
/// representative of widely flown Estes and AeroTech motors (impulse, average
/// thrust, burn time, propellant/total mass, casing diameter and delay options).
/// They are seeded into SwiftData on first launch so the simulator and catalog
/// have data to work with out of the box; users can add their own custom motors.
enum MotorCatalog {

    /// A plain description of one motor, used only to seed `Motor` records.
    struct Entry {
        let designation: String
        let manufacturer: String
        let totalImpulseNs: Double
        let avgThrustN: Double
        let burnTimeS: Double
        let propMassG: Double
        let totalMassG: Double
        let diameterMm: Double
        let delaysCSV: String
    }

    /// ~12 representative motors spanning impulse classes 1/2A through F.
    static let all: [Entry] = [
        // --- Estes black-powder motors (18 mm) ----------------------------
        Entry(designation: "1/2A3", manufacturer: "Estes",
              totalImpulseNs: 1.13, avgThrustN: 3.1, burnTimeS: 0.4,
              propMassG: 1.6, totalMassG: 7.8, diameterMm: 18, delaysCSV: "2,4"),
        Entry(designation: "A8", manufacturer: "Estes",
              totalImpulseNs: 2.5, avgThrustN: 4.3, burnTimeS: 0.5,
              propMassG: 3.1, totalMassG: 16.2, diameterMm: 18, delaysCSV: "3,5"),
        Entry(designation: "B4", manufacturer: "Estes",
              totalImpulseNs: 4.3, avgThrustN: 4.3, burnTimeS: 1.0,
              propMassG: 5.6, totalMassG: 18.5, diameterMm: 18, delaysCSV: "2,4,6"),
        Entry(designation: "B6", manufacturer: "Estes",
              totalImpulseNs: 4.3, avgThrustN: 6.0, burnTimeS: 0.8,
              propMassG: 5.6, totalMassG: 18.5, diameterMm: 18, delaysCSV: "0,2,4,6"),
        Entry(designation: "C6", manufacturer: "Estes",
              totalImpulseNs: 8.8, avgThrustN: 6.0, burnTimeS: 1.6,
              propMassG: 10.8, totalMassG: 24.0, diameterMm: 18, delaysCSV: "0,3,5,7"),
        Entry(designation: "C11", manufacturer: "Estes",
              totalImpulseNs: 8.8, avgThrustN: 11.0, burnTimeS: 0.8,
              propMassG: 10.6, totalMassG: 25.6, diameterMm: 24, delaysCSV: "0,3,5,7"),
        // --- Estes D & E (24 mm) ------------------------------------------
        Entry(designation: "D12", manufacturer: "Estes",
              totalImpulseNs: 16.8, avgThrustN: 12.0, burnTimeS: 1.6,
              propMassG: 21.1, totalMassG: 42.7, diameterMm: 24, delaysCSV: "0,3,5,7"),
        Entry(designation: "E12", manufacturer: "Estes",
              totalImpulseNs: 30.0, avgThrustN: 12.0, burnTimeS: 2.4,
              propMassG: 35.8, totalMassG: 57.7, diameterMm: 24, delaysCSV: "0,4,6,8"),
        // --- AeroTech composite motors (24 / 29 mm) -----------------------
        Entry(designation: "D21", manufacturer: "AeroTech",
              totalImpulseNs: 17.6, avgThrustN: 21.0, burnTimeS: 0.83,
              propMassG: 10.5, totalMassG: 38.0, diameterMm: 24, delaysCSV: "4,7"),
        Entry(designation: "E18", manufacturer: "AeroTech",
              totalImpulseNs: 35.6, avgThrustN: 18.0, burnTimeS: 1.97,
              propMassG: 20.4, totalMassG: 55.0, diameterMm: 24, delaysCSV: "4,7,10"),
        Entry(designation: "F24", manufacturer: "AeroTech",
              totalImpulseNs: 49.6, avgThrustN: 24.0, burnTimeS: 2.07,
              propMassG: 27.0, totalMassG: 64.0, diameterMm: 29, delaysCSV: "4,7,10"),
        Entry(designation: "F42", manufacturer: "AeroTech",
              totalImpulseNs: 60.0, avgThrustN: 42.0, burnTimeS: 1.43,
              propMassG: 32.0, totalMassG: 71.0, diameterMm: 29, delaysCSV: "4,6,8"),
    ]

    /// Build fresh `Motor` instances from the catalog entries.
    static func makeMotors() -> [Motor] {
        all.map { e in
            Motor(designation: e.designation,
                  manufacturer: e.manufacturer,
                  totalImpulseNs: e.totalImpulseNs,
                  avgThrustN: e.avgThrustN,
                  burnTimeS: e.burnTimeS,
                  propMassG: e.propMassG,
                  totalMassG: e.totalMassG,
                  diameterMm: e.diameterMm,
                  delaysCSV: e.delaysCSV,
                  isCustom: false)
        }
    }
}
