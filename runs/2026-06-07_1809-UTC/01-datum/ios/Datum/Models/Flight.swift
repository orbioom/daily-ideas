import Foundation
import SwiftData

/// A saved weight & balance plan for a single flight. It snapshots the aircraft
/// parameters and CG envelope at build time so a saved flight never changes if
/// the aircraft profile is later edited.
@Model
final class Flight {
    var id: UUID = UUID()
    var name: String = ""
    var date: Date = Date()

    // Snapshot of aircraft identity & parameters.
    var aircraftTail: String = ""
    var aircraftModel: String = ""
    var emptyWeight: Double = 0
    var emptyArm: Double = 0

    // Fuel plan.
    var fuelGal: Double = 0
    var plannedBurnGal: Double = 0
    var taxiBurnGal: Double = 0
    var fuelArm: Double = 0
    var fuelWeightPerGal: Double = 6.0

    var notes: String = ""

    /// The CG envelope captured at build time, encoded as JSON of `[EnvelopeVertex]`.
    var envelopeData: String = "[]"

    @Relationship(deleteRule: .cascade, inverse: \StationLoad.flight)
    var loads: [StationLoad] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        date: Date = Date(),
        aircraftTail: String = "",
        aircraftModel: String = "",
        emptyWeight: Double = 0,
        emptyArm: Double = 0,
        fuelGal: Double = 0,
        plannedBurnGal: Double = 0,
        taxiBurnGal: Double = 0,
        fuelArm: Double = 0,
        fuelWeightPerGal: Double = 6.0,
        notes: String = "",
        envelopeData: String = "[]",
        loads: [StationLoad] = []
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.aircraftTail = aircraftTail
        self.aircraftModel = aircraftModel
        self.emptyWeight = emptyWeight
        self.emptyArm = emptyArm
        self.fuelGal = fuelGal
        self.plannedBurnGal = plannedBurnGal
        self.taxiBurnGal = taxiBurnGal
        self.fuelArm = fuelArm
        self.fuelWeightPerGal = fuelWeightPerGal
        self.notes = notes
        self.envelopeData = envelopeData
        self.loads = loads
    }

    /// Decodes the snapshotted envelope vertices. Returns an empty array if the
    /// data is missing or malformed (never throws on a user path).
    var envelopeVertices: [EnvelopeVertex] {
        guard let data = envelopeData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([EnvelopeVertex].self, from: data)
        else { return [] }
        return decoded
    }

    /// Loads sorted by their station order.
    var orderedLoads: [StationLoad] {
        loads.sorted { $0.order < $1.order }
    }
}

/// A lightweight Codable envelope vertex used for snapshotting into a Flight.
struct EnvelopeVertex: Codable, Hashable {
    var cg: Double
    var weight: Double

    /// Encodes a list of vertices to a JSON string for storage.
    static func encode(_ vertices: [EnvelopeVertex]) -> String {
        guard let data = try? JSONEncoder().encode(vertices),
              let string = String(data: data, encoding: .utf8)
        else { return "[]" }
        return string
    }
}
