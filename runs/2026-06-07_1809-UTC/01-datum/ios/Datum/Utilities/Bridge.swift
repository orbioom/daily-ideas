import Foundation

/// Adapters that turn SwiftData models into the engine's pure value inputs, plus
/// small input-parsing helpers used by the forms. Kept out of WBEngine so the
/// engine stays free of any model knowledge.

extension WBEngine.FlightInputs {

    /// Builds engine inputs from a saved Flight (uses its snapshotted envelope).
    ///
    /// Weight limits are resolved from the matching live `aircraft` when one can
    /// be found by tail number; otherwise the envelope's own maximum weight is
    /// used so a saved flight whose aircraft was deleted still gets a sensible
    /// gross-weight check. This keeps the snapshot self-sufficient.
    init(flight: Flight, aircraft: Aircraft?) {
        let envelope = flight.envelopeVertices
        let envelopeMaxWeight = envelope.map(\.weight).max() ?? 0
        let ramp = aircraft?.maxRampWeight ?? envelopeMaxWeight
        let takeoff = aircraft?.maxTakeoffWeight ?? envelopeMaxWeight
        let landing = aircraft?.maxLandingWeight ?? envelopeMaxWeight
        let zeroFuel = aircraft?.maxZeroFuelWeight ?? 0

        self.init(
            emptyWeight: flight.emptyWeight,
            emptyArm: flight.emptyArm,
            fuelGal: flight.fuelGal,
            plannedBurnGal: flight.plannedBurnGal,
            taxiBurnGal: flight.taxiBurnGal,
            fuelArm: flight.fuelArm,
            fuelWeightPerGal: flight.fuelWeightPerGal,
            loads: flight.orderedLoads.map { (label: $0.stationName, weight: $0.weight, arm: $0.arm) },
            envelope: envelope,
            maxRampWeight: ramp,
            maxTakeoffWeight: takeoff,
            maxLandingWeight: landing,
            maxZeroFuelWeight: zeroFuel
        )
    }
}

/// Parsing helpers for free-text numeric fields. They never throw; invalid input
/// resolves to a safe default so the UI stays calm.
enum NumParse {
    /// Parses a non-negative Double from a string, clamped at 0.
    static func nonNegative(_ s: String) -> Double {
        max(0, Double(s.replacingOccurrences(of: ",", with: "")) ?? 0)
    }

    /// Parses any Double (allows negatives), defaulting to 0.
    static func any(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    /// Whether a string parses to a finite number.
    static func isValid(_ s: String) -> Bool {
        guard let v = Double(s.replacingOccurrences(of: ",", with: "")) else { return false }
        return v.isFinite
    }
}
