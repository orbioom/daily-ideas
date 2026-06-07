import Foundation
import SwiftData

/// A logged flight: the prediction made at design time plus, optionally, the
/// altitude actually measured at the field. An `actualAltitudeM` of 0 means the
/// real altitude has not been recorded yet.
@Model
final class Flight {
    var id: UUID = UUID()
    var date: Date = Date()
    var rocketName: String = ""
    var motorDesignation: String = ""
    var predictedAltitudeM: Double = 0
    /// Measured altitude in metres. 0 = not yet recorded.
    var actualAltitudeM: Double = 0
    var maxVelocityMS: Double = 0
    var recommendedDelayS: Double = 0
    var delayUsedS: Double = 0
    var thrustToWeight: Double = 0
    var stabilityCal: Double = 0
    /// Raw value for the `Recovery` enum.
    var recoveryRaw: String = Recovery.parachute.rawValue
    var windKph: Double = 0
    var notes: String = ""

    @Relationship var rocket: Rocket?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        rocketName: String = "",
        motorDesignation: String = "",
        predictedAltitudeM: Double = 0,
        actualAltitudeM: Double = 0,
        maxVelocityMS: Double = 0,
        recommendedDelayS: Double = 0,
        delayUsedS: Double = 0,
        thrustToWeight: Double = 0,
        stabilityCal: Double = 0,
        recoveryRaw: String = Recovery.parachute.rawValue,
        windKph: Double = 0,
        notes: String = "",
        rocket: Rocket? = nil
    ) {
        self.id = id
        self.date = date
        self.rocketName = rocketName
        self.motorDesignation = motorDesignation
        self.predictedAltitudeM = predictedAltitudeM
        self.actualAltitudeM = actualAltitudeM
        self.maxVelocityMS = maxVelocityMS
        self.recommendedDelayS = recommendedDelayS
        self.delayUsedS = delayUsedS
        self.thrustToWeight = thrustToWeight
        self.stabilityCal = stabilityCal
        self.recoveryRaw = recoveryRaw
        self.windKph = windKph
        self.notes = notes
        self.rocket = rocket
    }
}

extension Flight {
    var recovery: Recovery {
        get { Recovery(rawValue: recoveryRaw) ?? .parachute }
        set { recoveryRaw = newValue.rawValue }
    }

    var hasActual: Bool { actualAltitudeM > 0 }

    /// Signed difference between measured and predicted altitude in metres.
    /// Positive means the rocket flew higher than predicted.
    var altitudeDeltaM: Double { actualAltitudeM - predictedAltitudeM }

    /// Prediction error as a fraction of the prediction (0.12 = 12% off).
    var predictionErrorFraction: Double? {
        guard hasActual, predictedAltitudeM > 0 else { return nil }
        return abs(altitudeDeltaM) / predictedAltitudeM
    }
}

/// How the rocket comes back down.
enum Recovery: String, CaseIterable, Identifiable {
    case parachute
    case streamer
    case tumble
    case gliderHeloOther

    var id: String { rawValue }

    var label: String {
        switch self {
        case .parachute:      return "Parachute"
        case .streamer:       return "Streamer"
        case .tumble:         return "Tumble"
        case .gliderHeloOther: return "Glider / Helo / Other"
        }
    }

    var icon: String {
        switch self {
        case .parachute:       return "umbrella"
        case .streamer:        return "wind"
        case .tumble:          return "tornado"
        case .gliderHeloOther: return "paperplane"
        }
    }
}
