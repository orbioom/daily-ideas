import Foundation
import SwiftData

/// Seeds two realistic aircraft and a handful of flights so a first-run user has
/// meaningful charts and lists to explore. Idempotent: only seeds an empty store.
enum SampleData {

    /// Inserts sample aircraft and flights if the store has no aircraft yet.
    static func seedIfEmpty(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Aircraft>())) ?? []
        guard existing.isEmpty else { return }
        seed(context)
    }

    /// Inserts the full sample set unconditionally.
    static func seed(_ context: ModelContext) {
        let c172 = makeCessna172()
        let archer = makeArcher()
        context.insert(c172)
        context.insert(archer)

        for flight in makeFlights(c172: c172, archer: archer) {
            context.insert(flight)
        }
        try? context.save()
    }

    // MARK: - Aircraft

    private static func makeCessna172() -> Aircraft {
        let ac = Aircraft(
            tailNumber: "N5271T",
            model: "Cessna 172S Skyhawk",
            emptyWeight: 1680, emptyArm: 39.0,
            maxRampWeight: 2558,
            maxTakeoffWeight: 2550,
            maxLandingWeight: 2550,
            maxZeroFuelWeight: 0,
            fuelCapacityGal: 56, usableFuelGal: 53,
            fuelArm: 48, fuelWeightPerGal: 6.0, taxiBurnGal: 1.4
        )
        ac.stations = [
            Station(name: "Front seats", arm: 37, maxWeight: 0, defaultWeight: 340, order: 0, aircraft: ac),
            Station(name: "Rear seats", arm: 73, maxWeight: 0, defaultWeight: 0, order: 1, aircraft: ac),
            Station(name: "Baggage A", arm: 95, maxWeight: 120, defaultWeight: 20, order: 2, aircraft: ac),
            Station(name: "Baggage B", arm: 123, maxWeight: 50, defaultWeight: 0, order: 3, aircraft: ac)
        ]
        // 172S normal-category CG envelope (cg in, weight lb), perimeter order.
        ac.envelope = [
            EnvelopePoint(cgArm: 35.0, weight: 1500, order: 0, aircraft: ac),
            EnvelopePoint(cgArm: 35.0, weight: 1950, order: 1, aircraft: ac),
            EnvelopePoint(cgArm: 40.5, weight: 2550, order: 2, aircraft: ac),
            EnvelopePoint(cgArm: 47.3, weight: 2550, order: 3, aircraft: ac),
            EnvelopePoint(cgArm: 47.3, weight: 1500, order: 4, aircraft: ac)
        ]
        return ac
    }

    private static func makeArcher() -> Aircraft {
        let ac = Aircraft(
            tailNumber: "N8143W",
            model: "Piper PA-28-181 Archer III",
            emptyWeight: 1640, emptyArm: 86.0,
            maxRampWeight: 2558,
            maxTakeoffWeight: 2550,
            maxLandingWeight: 2550,
            maxZeroFuelWeight: 0,
            fuelCapacityGal: 50, usableFuelGal: 48,
            fuelArm: 95, fuelWeightPerGal: 6.0, taxiBurnGal: 1.2
        )
        ac.stations = [
            Station(name: "Front seats", arm: 80.5, maxWeight: 0, defaultWeight: 330, order: 0, aircraft: ac),
            Station(name: "Rear seats", arm: 118.1, maxWeight: 0, defaultWeight: 0, order: 1, aircraft: ac),
            Station(name: "Baggage", arm: 142.8, maxWeight: 200, defaultWeight: 25, order: 2, aircraft: ac)
        ]
        // PA-28-181 CG envelope.
        ac.envelope = [
            EnvelopePoint(cgArm: 82.0, weight: 1500, order: 0, aircraft: ac),
            EnvelopePoint(cgArm: 82.0, weight: 1950, order: 1, aircraft: ac),
            EnvelopePoint(cgArm: 88.6, weight: 2550, order: 2, aircraft: ac),
            EnvelopePoint(cgArm: 93.0, weight: 2550, order: 3, aircraft: ac),
            EnvelopePoint(cgArm: 93.0, weight: 1500, order: 4, aircraft: ac)
        ]
        return ac
    }

    // MARK: - Flights

    private static func makeFlights(c172: Aircraft, archer: Aircraft) -> [Flight] {
        let cal = Calendar.current
        let today = Date()

        func snapshot(_ ac: Aircraft) -> String {
            EnvelopeVertex.encode(ac.orderedEnvelope.map { EnvelopeVertex(cg: $0.cgArm, weight: $0.weight) })
        }

        // 1. Cessna — solo training, comfortably in envelope.
        let f1 = Flight(
            name: "KPAO Pattern Work",
            date: cal.date(byAdding: .day, value: -2, to: today) ?? today,
            aircraftTail: c172.tailNumber, aircraftModel: c172.model,
            emptyWeight: c172.emptyWeight, emptyArm: c172.emptyArm,
            fuelGal: 40, plannedBurnGal: 9, taxiBurnGal: c172.taxiBurnGal,
            fuelArm: c172.fuelArm, fuelWeightPerGal: c172.fuelWeightPerGal,
            notes: "Solo currency, three landings.",
            envelopeData: snapshot(c172)
        )
        f1.loads = [
            StationLoad(stationName: "Front seats", arm: 37, weight: 180, order: 0, flight: f1),
            StationLoad(stationName: "Rear seats", arm: 73, weight: 0, order: 1, flight: f1),
            StationLoad(stationName: "Baggage A", arm: 95, weight: 15, order: 2, flight: f1),
            StationLoad(stationName: "Baggage B", arm: 123, weight: 0, order: 3, flight: f1)
        ]

        // 2. Cessna — four people + bags, deliberately over MTOW / aft to show "Out".
        let f2 = Flight(
            name: "Tahoe Day Trip",
            date: cal.date(byAdding: .day, value: -1, to: today) ?? today,
            aircraftTail: c172.tailNumber, aircraftModel: c172.model,
            emptyWeight: c172.emptyWeight, emptyArm: c172.emptyArm,
            fuelGal: 53, plannedBurnGal: 16, taxiBurnGal: c172.taxiBurnGal,
            fuelArm: c172.fuelArm, fuelWeightPerGal: c172.fuelWeightPerGal,
            notes: "Four adults + luggage — recheck, looks heavy and aft.",
            envelopeData: snapshot(c172)
        )
        f2.loads = [
            StationLoad(stationName: "Front seats", arm: 37, weight: 360, order: 0, flight: f2),
            StationLoad(stationName: "Rear seats", arm: 73, weight: 330, order: 1, flight: f2),
            StationLoad(stationName: "Baggage A", arm: 95, weight: 80, order: 2, flight: f2),
            StationLoad(stationName: "Baggage B", arm: 123, weight: 30, order: 3, flight: f2)
        ]

        // 3. Archer — two up, cross-country, in envelope.
        let f3 = Flight(
            name: "KSQL → KMRY XC",
            date: cal.date(byAdding: .day, value: -5, to: today) ?? today,
            aircraftTail: archer.tailNumber, aircraftModel: archer.model,
            emptyWeight: archer.emptyWeight, emptyArm: archer.emptyArm,
            fuelGal: 44, plannedBurnGal: 13, taxiBurnGal: archer.taxiBurnGal,
            fuelArm: archer.fuelArm, fuelWeightPerGal: archer.fuelWeightPerGal,
            notes: "Coastal cross-country with an instructor.",
            envelopeData: snapshot(archer)
        )
        f3.loads = [
            StationLoad(stationName: "Front seats", arm: 80.5, weight: 350, order: 0, flight: f3),
            StationLoad(stationName: "Rear seats", arm: 118.1, weight: 0, order: 1, flight: f3),
            StationLoad(stationName: "Baggage", arm: 142.8, weight: 30, order: 2, flight: f3)
        ]

        // 4. Archer — full load, fine on weight, near aft limit.
        let f4 = Flight(
            name: "Family Visit",
            date: cal.date(byAdding: .day, value: -8, to: today) ?? today,
            aircraftTail: archer.tailNumber, aircraftModel: archer.model,
            emptyWeight: archer.emptyWeight, emptyArm: archer.emptyArm,
            fuelGal: 38, plannedBurnGal: 12, taxiBurnGal: archer.taxiBurnGal,
            fuelArm: archer.fuelArm, fuelWeightPerGal: archer.fuelWeightPerGal,
            notes: "Two adults up front, two kids in back.",
            envelopeData: snapshot(archer)
        )
        f4.loads = [
            StationLoad(stationName: "Front seats", arm: 80.5, weight: 340, order: 0, flight: f4),
            StationLoad(stationName: "Rear seats", arm: 118.1, weight: 140, order: 1, flight: f4),
            StationLoad(stationName: "Baggage", arm: 142.8, weight: 40, order: 2, flight: f4)
        ]

        return [f1, f2, f3, f4]
    }
}
