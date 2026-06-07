import Foundation
import SwiftData

enum SampleData {
    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        let specs: [(String, String, String, String, Int, UInt32, Double)] = [
            // name, brand, ref, movement, powerReserve, accent, baseRate s/d
            ("Daily Diver", "Seiko", "SPB143", "6R35", 70, 0x4E6BA8, 8.5),
            ("Speedy", "Omega", "311.30.42", "Cal. 3861", 50, 0xC08A3E, 2.0),
            ("Field", "Hamilton", "H70455", "H-10", 80, 0x4FB98C, -3.5),
            ("Datejust", "Rolex", "126200", "Cal. 3230", 70, 0x8B8FA3, 1.5),
            ("Weekender", "Tissot", "T137", "Powermatic 80", 80, 0xC0553E, 14.0)
        ]

        for (i, s) in specs.enumerated() {
            let w = Watch(name: s.0, brand: s.1, modelRef: s.2, movement: s.3,
                          purchaseDate: cal.date(byAdding: .month, value: -(i * 7 + 3), to: .now),
                          serviceIntervalYears: 5,
                          lastServiced: cal.date(byAdding: .month, value: -(i * 11 + 4), to: .now),
                          powerReserveHours: s.4,
                          isFavorite: i == 1,
                          accentHex: s.5,
                          notes: i == 0 ? "Wears it most days; runs a touch fast off the wrist." : "")
            context.insert(w)

            // Build a believable drift: offset grows roughly linearly at baseRate.
            let positions: [WatchPosition] = [.onWrist, .dialUp, .crownDown, .dialDown]
            var cumulative = 0.0
            for d in stride(from: 24, through: 0, by: -3) {
                let ts = cal.date(byAdding: .day, value: -d, to: .now) ?? .now
                let elapsed = Double(24 - d)
                cumulative = s.6 * elapsed + Double.random(in: -2.5...2.5)
                let m = WatchMeasurement(
                    timestamp: ts,
                    offsetSeconds: cumulative,
                    position: positions[(d / 3) % positions.count]
                )
                m.watch = w
                w.measurements.append(m)
            }
        }
        try? context.save()
    }
}
