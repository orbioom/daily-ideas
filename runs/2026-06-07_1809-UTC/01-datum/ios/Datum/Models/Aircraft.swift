import Foundation
import SwiftData

/// A pilot's aircraft profile: empty weight & arm, loading stations, fuel
/// parameters, and the CG envelope polygon. Built once, reused for every flight.
@Model
final class Aircraft {
    var id: UUID = UUID()
    var tailNumber: String = ""
    var model: String = ""

    /// Empty (basic empty) weight in pounds and its arm in inches aft of datum.
    var emptyWeight: Double = 0
    var emptyArm: Double = 0

    /// Maximum certificated weights (lb). A value of 0 means "not applicable".
    var maxRampWeight: Double = 0
    var maxTakeoffWeight: Double = 0
    var maxLandingWeight: Double = 0
    var maxZeroFuelWeight: Double = 0

    /// Fuel system parameters.
    var fuelCapacityGal: Double = 0
    var usableFuelGal: Double = 0
    var fuelArm: Double = 0
    var fuelWeightPerGal: Double = 6.0   // 100LL avgas
    var taxiBurnGal: Double = 1.4

    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Station.aircraft)
    var stations: [Station] = []

    @Relationship(deleteRule: .cascade, inverse: \EnvelopePoint.aircraft)
    var envelope: [EnvelopePoint] = []

    init(
        id: UUID = UUID(),
        tailNumber: String = "",
        model: String = "",
        emptyWeight: Double = 0,
        emptyArm: Double = 0,
        maxRampWeight: Double = 0,
        maxTakeoffWeight: Double = 0,
        maxLandingWeight: Double = 0,
        maxZeroFuelWeight: Double = 0,
        fuelCapacityGal: Double = 0,
        usableFuelGal: Double = 0,
        fuelArm: Double = 0,
        fuelWeightPerGal: Double = 6.0,
        taxiBurnGal: Double = 1.4,
        createdAt: Date = Date(),
        stations: [Station] = [],
        envelope: [EnvelopePoint] = []
    ) {
        self.id = id
        self.tailNumber = tailNumber
        self.model = model
        self.emptyWeight = emptyWeight
        self.emptyArm = emptyArm
        self.maxRampWeight = maxRampWeight
        self.maxTakeoffWeight = maxTakeoffWeight
        self.maxLandingWeight = maxLandingWeight
        self.maxZeroFuelWeight = maxZeroFuelWeight
        self.fuelCapacityGal = fuelCapacityGal
        self.usableFuelGal = usableFuelGal
        self.fuelArm = fuelArm
        self.fuelWeightPerGal = fuelWeightPerGal
        self.taxiBurnGal = taxiBurnGal
        self.createdAt = createdAt
        self.stations = stations
        self.envelope = envelope
    }

    /// Stations sorted by their display order.
    var orderedStations: [Station] {
        stations.sorted { $0.order < $1.order }
    }

    /// Envelope vertices sorted by their polygon order.
    var orderedEnvelope: [EnvelopePoint] {
        envelope.sorted { $0.order < $1.order }
    }
}
