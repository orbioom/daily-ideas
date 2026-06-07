import Foundation

/// A single sampled point along the simulated trajectory.
struct TrajectoryPoint: Identifiable, Sendable {
    let id = UUID()
    let t: Double          // seconds since liftoff
    let altitude: Double   // metres
    let velocity: Double   // metres / second
}

/// The full result of a flight simulation.
struct FlightResult: Sendable {
    let apogeeM: Double
    let maxVelocityMS: Double
    let timeToApogeeS: Double
    let burnoutAltM: Double
    let burnoutVelMS: Double
    /// Time from burnout to apogee — the ideal ejection delay.
    let recommendedDelayS: Double
    let thrustToWeight: Double
    /// Nearest available delay from the motor (or nil if the motor lists none).
    let nearestAvailableDelayS: Double?
    let trajectory: [TrajectoryPoint]

    /// A liftoff thrust-to-weight ratio below ~5:1 is considered marginal.
    var thrustToWeightIsLow: Bool { thrustToWeight < 5 }
}

/// Pure physics for model-rocket flight prediction.
///
/// The flight is integrated in two phases with a fixed timestep (Euler method):
///   1. **Boost** — constant average thrust over the burn time while the
///      propellant mass burns off linearly.
///   2. **Coast** — no thrust; the rocket decelerates under gravity and drag
///      until vertical velocity reaches zero (apogee).
///
/// Drag uses the quadratic model F_d = ½·ρ·Cd·A·v². The model is one-dimensional
/// (purely vertical) which is the standard first-order approximation used by
/// hobby altitude calculators; it ignores wind, off-vertical flight and the
/// brief thrust transients, so it is a planning estimate, not a guarantee.
enum FlightEngine {

    // Physical constants.
    static let g: Double = 9.80665          // gravitational acceleration, m/s²
    static let rho: Double = 1.225          // air density at sea level, kg/m³
    static let dt: Double = 0.01            // integration timestep, s
    static let maxFlightTime: Double = 60   // hard cap to avoid runaway loops, s

    /// An immutable, value-type snapshot of everything the integrator needs.
    /// Decoupling from the SwiftData models lets the heavy loop run on a
    /// detached task without touching managed objects off their context.
    struct Input: Sendable {
        var diameterMm: Double
        var massGramsDry: Double
        var cd: Double
        var totalMassG: Double
        var propMassG: Double
        var avgThrustN: Double
        var burnTimeS: Double
        var delays: [Double]

        init(diameterMm: Double, massGramsDry: Double, cd: Double,
             totalMassG: Double, propMassG: Double,
             avgThrustN: Double, burnTimeS: Double, delays: [Double]) {
            self.diameterMm = diameterMm
            self.massGramsDry = massGramsDry
            self.cd = cd
            self.totalMassG = totalMassG
            self.propMassG = propMassG
            self.avgThrustN = avgThrustN
            self.burnTimeS = burnTimeS
            self.delays = delays
        }

        @MainActor
        init(rocket: Rocket, motor: Motor) {
            self.init(diameterMm: rocket.diameterMm,
                      massGramsDry: rocket.massGramsDry,
                      cd: rocket.cd,
                      totalMassG: motor.totalMassG,
                      propMassG: motor.propMassG,
                      avgThrustN: motor.avgThrustN,
                      burnTimeS: motor.burnTimeS,
                      delays: motor.delays)
        }
    }

    /// Convenience overload used where the models are already on the main actor
    /// (e.g. sample-data seeding). Snapshots then runs the value-type path.
    @MainActor
    static func simulate(rocket: Rocket, motor: Motor) -> FlightResult {
        simulate(Input(rocket: rocket, motor: motor))
    }

    /// Run the full simulation from an immutable input snapshot.
    /// All guards return a zeroed result rather than crashing on bad input.
    static func simulate(_ input: Input) -> FlightResult {
        let dryKg = input.massGramsDry / 1000.0
        let totalMotorKg = input.totalMassG / 1000.0
        let propKg = input.propMassG / 1000.0
        let burn = input.burnTimeS

        // Liftoff (wet) mass with the motor installed.
        let m0 = dryKg + totalMotorKg

        // Frontal reference area from the body-tube diameter (m²).
        let radiusM = (input.diameterMm / 2000.0)   // mm → m, and /2 for radius
        let area = Double.pi * radiusM * radiusM
        // Drag constant k so that drag force = k · v².
        let k = 0.5 * rho * input.cd * area

        // Guard against unusable input that would divide by zero.
        guard m0 > 0, burn > 0, input.diameterMm > 0 else {
            return FlightResult(
                apogeeM: 0, maxVelocityMS: 0, timeToApogeeS: 0,
                burnoutAltM: 0, burnoutVelMS: 0, recommendedDelayS: 0,
                thrustToWeight: 0, nearestAvailableDelayS: nil, trajectory: []
            )
        }

        let thrust = input.avgThrustN
        let thrustToWeight = thrust / (m0 * g)

        var t = 0.0
        var v = 0.0          // vertical velocity, m/s
        var alt = 0.0        // altitude, m
        var maxV = 0.0

        var samples: [TrajectoryPoint] = [TrajectoryPoint(t: 0, altitude: 0, velocity: 0)]
        // Sample roughly every 50 ms to keep the chart light but smooth.
        let sampleEvery = 5
        var step = 0

        // --- Phase 1: Boost ------------------------------------------------
        // Mass falls linearly from m0 to (m0 − propKg) over the burn.
        while t < burn && t < maxFlightTime {
            let burnFraction = min(1.0, t / burn)
            let m = max(m0 - propKg * burnFraction, 1e-4)   // guard mass > 0
            // Net acceleration: thrust, drag (always opposes motion → −v²
            // while ascending), and gravity.
            let a = (thrust - k * v * v - m * g) / m
            v += a * dt
            alt += v * dt
            t += dt
            if v > maxV { maxV = v }
            step += 1
            if step % sampleEvery == 0 {
                samples.append(TrajectoryPoint(t: t, altitude: max(0, alt), velocity: v))
            }
        }

        let burnoutAlt = max(0, alt)
        let burnoutVel = v

        // --- Phase 2: Coast ------------------------------------------------
        // Motor is spent: dry mass plus the empty casing remains.
        let coastMass = max(dryKg + (totalMotorKg - propKg), 1e-4)   // guard > 0
        let burnoutTime = t

        while v > 0 && t < maxFlightTime {
            // Drag opposes motion; sign(v) keeps it correct near the top.
            let drag = k * v * v * (v >= 0 ? 1.0 : -1.0)
            let a = (-drag - coastMass * g) / coastMass
            v += a * dt
            alt += v * dt
            t += dt
            step += 1
            if step % sampleEvery == 0 {
                samples.append(TrajectoryPoint(t: t, altitude: max(0, alt), velocity: max(0, v)))
            }
        }

        let apogee = max(0, alt)
        let timeToApogee = t
        let recommendedDelay = max(0, timeToApogee - burnoutTime)

        // Append the apogee point exactly so the chart peak is precise.
        samples.append(TrajectoryPoint(t: timeToApogee, altitude: apogee, velocity: 0))

        let nearest = nearestDelay(to: recommendedDelay, from: input.delays)

        return FlightResult(
            apogeeM: apogee,
            maxVelocityMS: maxV,
            timeToApogeeS: timeToApogee,
            burnoutAltM: burnoutAlt,
            burnoutVelMS: burnoutVel,
            recommendedDelayS: recommendedDelay,
            thrustToWeight: thrustToWeight,
            nearestAvailableDelayS: nearest,
            trajectory: samples
        )
    }

    /// Choose the closest available ejection delay to the recommended value.
    static func nearestDelay(to target: Double, from delays: [Double]) -> Double? {
        guard !delays.isEmpty else { return nil }
        return delays.min(by: { abs($0 - target) < abs($1 - target) })
    }
}

// MARK: - Unit conversion

/// Metres ↔ feet helpers for display, driven by the units preference.
enum LengthUnit: String, CaseIterable, Identifiable {
    case meters
    case feet

    var id: String { rawValue }
    var label: String { self == .meters ? "Meters" : "Feet" }
    var symbol: String { self == .meters ? "m" : "ft" }

    /// Convert a value in metres into this unit.
    func from(meters: Double) -> Double {
        self == .meters ? meters : meters * 3.280839895
    }
}
