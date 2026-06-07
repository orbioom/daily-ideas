import Foundation
import SwiftData

/// First-run seeding. Inserts the built-in motor catalog, a few example rockets
/// and some logged flights (a couple with measured altitudes) so a brand-new
/// install has something to explore. Seeding only happens when the store is empty.
enum SampleData {

    /// Seed the store if it has no rockets and no motors yet. Idempotent: calling
    /// it again on a populated store does nothing.
    @MainActor
    static func seedIfEmpty(_ context: ModelContext) {
        let rocketCount = (try? context.fetchCount(FetchDescriptor<Rocket>())) ?? 0
        let motorCount = (try? context.fetchCount(FetchDescriptor<Motor>())) ?? 0
        guard rocketCount == 0 && motorCount == 0 else { return }
        seed(context)
    }

    /// Insert the motors, rockets and example flights. Persists once at the end.
    @MainActor
    static func seed(_ context: ModelContext) {
        // Motors from the built-in catalog.
        let motors = MotorCatalog.makeMotors()
        for m in motors { context.insert(m) }
        let byDesignation = Dictionary(uniqueKeysWithValues: motors.map { ($0.designation, $0) })

        // Three example rockets with CG/CP chosen so calibers land near 1–2.5.
        let alpha = Rocket(
            name: "Alpha III",
            diameterMm: 24.8, massGramsDry: 34, cd: 0.6,
            cgFromNoseMm: 215, cpFromNoseMm: 252, lengthMm: 311,
            notes: "Classic Estes starter kit. Great on B and C motors.",
            createdAt: Date().addingTimeInterval(-86400 * 30))
        let bertha = Rocket(
            name: "Big Bertha",
            diameterMm: 41.6, massGramsDry: 76, cd: 0.6,
            cgFromNoseMm: 380, cpFromNoseMm: 444, lengthMm: 610,
            notes: "Big, slow and stable. A crowd favourite on C and D.",
            createdAt: Date().addingTimeInterval(-86400 * 21))
        let initiator = Rocket(
            name: "Initiator",
            diameterMm: 38.0, massGramsDry: 140, cd: 0.55,
            cgFromNoseMm: 470, cpFromNoseMm: 535, lengthMm: 660,
            notes: "Mid-power bird. Steps up to E and F composite motors.",
            createdAt: Date().addingTimeInterval(-86400 * 10))
        for r in [alpha, bertha, initiator] { context.insert(r) }

        // Helper to build a flight from a real simulation so predictions match
        // what the in-app simulator would produce.
        func makeFlight(rocket: Rocket,
                        motorKey: String,
                        daysAgo: Double,
                        actualM: Double,
                        delayUsed: Double,
                        recovery: Recovery,
                        windKph: Double,
                        notes: String) -> Flight? {
            guard let motor = byDesignation[motorKey] else { return nil }
            let r = FlightEngine.simulate(rocket: rocket, motor: motor)
            let flight = Flight(
                date: Date().addingTimeInterval(-86400 * daysAgo),
                rocketName: rocket.name,
                motorDesignation: motor.designation,
                predictedAltitudeM: r.apogeeM,
                actualAltitudeM: actualM,
                maxVelocityMS: r.maxVelocityMS,
                recommendedDelayS: r.recommendedDelayS,
                delayUsedS: delayUsed,
                thrustToWeight: r.thrustToWeight,
                stabilityCal: rocket.stabilityCal,
                recoveryRaw: recovery.rawValue,
                windKph: windKph,
                notes: notes,
                rocket: rocket)
            return flight
        }

        let seeds: [Flight] = [
            makeFlight(rocket: alpha, motorKey: "C6", daysAgo: 28, actualM: 0,
                       delayUsed: 5, recovery: .parachute, windKph: 8,
                       notes: "First flight of the season, dead straight."),
            makeFlight(rocket: alpha, motorKey: "B6", daysAgo: 25, actualM: 0,
                       delayUsed: 4, recovery: .parachute, windKph: 12,
                       notes: "Lower and breezy — good recovery."),
            makeFlight(rocket: bertha, motorKey: "C6", daysAgo: 20, actualM: 0,
                       delayUsed: 5, recovery: .parachute, windKph: 6,
                       notes: "Lazy boost, perfect chute."),
            makeFlight(rocket: bertha, motorKey: "D12", daysAgo: 14, actualM: 0,
                       delayUsed: 5, recovery: .parachute, windKph: 10,
                       notes: "Stepped up to a D. Big and slow."),
            makeFlight(rocket: initiator, motorKey: "E18", daysAgo: 7, actualM: 0,
                       delayUsed: 7, recovery: .parachute, windKph: 5,
                       notes: "Composite debut. Smelled great."),
            makeFlight(rocket: initiator, motorKey: "F24", daysAgo: 2, actualM: 0,
                       delayUsed: 7, recovery: .parachute, windKph: 9,
                       notes: "Highest flight yet, GPS confirmed."),
        ].compactMap { $0 }

        // Fill in measured altitudes for a few flights, near (but not exactly on)
        // the prediction so the predicted-vs-actual insight has real data.
        for flight in seeds {
            switch (flight.rocketName, flight.motorDesignation) {
            case ("Alpha III", "C6"): flight.actualAltitudeM = flight.predictedAltitudeM * 0.93
            case ("Big Bertha", "C6"): flight.actualAltitudeM = flight.predictedAltitudeM * 1.06
            case ("Big Bertha", "D12"): flight.actualAltitudeM = flight.predictedAltitudeM * 0.97
            case ("Initiator", "F24"): flight.actualAltitudeM = flight.predictedAltitudeM * 1.02
            default: break
            }
            context.insert(flight)
        }

        try? context.save()
    }

    /// Remove every record from the store. Used by Settings → Erase all.
    @MainActor
    static func eraseAll(_ context: ModelContext) {
        try? context.delete(model: Flight.self)
        try? context.delete(model: Rocket.self)
        try? context.delete(model: Motor.self)
        try? context.save()
    }
}
