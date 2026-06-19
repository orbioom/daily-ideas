import Foundation

struct ProtocolPhase: Identifiable {
    let id = UUID()
    let name: String
    let type: TherapyType
    let durationSeconds: Int
    let temperatureCelsius: Double

    var durationDisplay: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        if s == 0 { return "\(m) min" }
        return "\(m)m \(s)s"
    }
}

struct TherapyProtocol: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let phases: [ProtocolPhase]
    let source: String

    var totalDurationSeconds: Int { phases.map(\.durationSeconds).reduce(0, +) }
    var totalMinutes: Int { totalDurationSeconds / 60 }
}

enum TherapyProtocols {
    static let all: [TherapyProtocol] = [
        TherapyProtocol(
            name: "Classic Finnish",
            subtitle: "Traditional 3-round sauna",
            phases: [
                ProtocolPhase(name: "Heat", type: .sauna, durationSeconds: 1200, temperatureCelsius: 80),
                ProtocolPhase(name: "Cool Down", type: .coldPlunge, durationSeconds: 300, temperatureCelsius: 15),
                ProtocolPhase(name: "Rest", type: .sauna, durationSeconds: 600, temperatureCelsius: 80),
                ProtocolPhase(name: "Cool Down", type: .coldPlunge, durationSeconds: 300, temperatureCelsius: 15),
                ProtocolPhase(name: "Final Heat", type: .sauna, durationSeconds: 1200, temperatureCelsius: 80),
                ProtocolPhase(name: "Final Cool", type: .coldPlunge, durationSeconds: 300, temperatureCelsius: 15)
            ],
            source: "Traditional Finnish method"
        ),
        TherapyProtocol(
            name: "Huberman Protocol",
            subtitle: "3 rounds, deep contrast therapy",
            phases: [
                ProtocolPhase(name: "Sauna Round 1", type: .sauna, durationSeconds: 1200, temperatureCelsius: 80),
                ProtocolPhase(name: "Cold Plunge 1", type: .coldPlunge, durationSeconds: 180, temperatureCelsius: 10),
                ProtocolPhase(name: "Sauna Round 2", type: .sauna, durationSeconds: 1200, temperatureCelsius: 80),
                ProtocolPhase(name: "Cold Plunge 2", type: .coldPlunge, durationSeconds: 180, temperatureCelsius: 10),
                ProtocolPhase(name: "Sauna Round 3", type: .sauna, durationSeconds: 1200, temperatureCelsius: 80),
                ProtocolPhase(name: "Cold Plunge 3", type: .coldPlunge, durationSeconds: 180, temperatureCelsius: 10)
            ],
            source: "Dr. Andrew Huberman, Huberman Lab"
        ),
        TherapyProtocol(
            name: "Wim Hof Cold",
            subtitle: "Ice bath with breathing prep",
            phases: [
                ProtocolPhase(name: "Breathwork Prep", type: .sauna, durationSeconds: 300, temperatureCelsius: 20),
                ProtocolPhase(name: "Ice Bath", type: .iceBath, durationSeconds: 120, temperatureCelsius: 5),
                ProtocolPhase(name: "Recovery", type: .sauna, durationSeconds: 300, temperatureCelsius: 20)
            ],
            source: "Wim Hof Method"
        ),
        TherapyProtocol(
            name: "Quick Recovery",
            subtitle: "Post-workout contrast",
            phases: [
                ProtocolPhase(name: "Sauna", type: .sauna, durationSeconds: 600, temperatureCelsius: 75),
                ProtocolPhase(name: "Cold Plunge", type: .coldPlunge, durationSeconds: 120, temperatureCelsius: 12)
            ],
            source: "Athlete recovery protocol"
        ),
        TherapyProtocol(
            name: "Beginner Cold",
            subtitle: "Gentle introduction to cold",
            phases: [
                ProtocolPhase(name: "Warm Shower", type: .steam, durationSeconds: 300, temperatureCelsius: 38),
                ProtocolPhase(name: "Cold End", type: .coldPlunge, durationSeconds: 30, temperatureCelsius: 18)
            ],
            source: "Beginner adaptation"
        )
    ]
}
