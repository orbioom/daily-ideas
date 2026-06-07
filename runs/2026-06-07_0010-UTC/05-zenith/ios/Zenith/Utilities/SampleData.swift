import Foundation
import SwiftData

enum SampleData {
    static func seed(into context: ModelContext) {
        let scopes = [
            Telescope(name: "8\" Dob", aperture: 203, focalLength: 1200, type: .dobsonian, isPrimary: true,
                      notes: "Workhorse for deep sky."),
            Telescope(name: "Travel Refractor", aperture: 80, focalLength: 480, type: .refractor,
                      notes: "Grab-and-go widefield."),
            Telescope(name: "C8 SCT", aperture: 203, focalLength: 2032, type: .sct,
                      notes: "Long focal length for planets.")
        ]
        for s in scopes { context.insert(s) }

        let eyepieces = [
            Eyepiece(name: "32mm Plössl", focalLength: 32, apparentFOV: 52, brand: "GSO"),
            Eyepiece(name: "25mm Plössl", focalLength: 25, apparentFOV: 52, brand: "GSO"),
            Eyepiece(name: "13mm Wide", focalLength: 13, apparentFOV: 68, brand: "ES"),
            Eyepiece(name: "9mm Wide", focalLength: 9, apparentFOV: 68, brand: "ES"),
            Eyepiece(name: "6mm Planetary", focalLength: 6, apparentFOV: 58, brand: "BST")
        ]
        for e in eyepieces { context.insert(e) }

        let cal = Calendar.current
        let logs: [(String, TargetType, String, String, Double, Int, Int, Int)] = [
            ("Orion Nebula", .nebula, "Orion", "13mm Wide", 92, 4, 4, 5),
            ("Andromeda Galaxy", .galaxy, "Andromeda", "32mm Plössl", 38, 3, 3, 4),
            ("Saturn", .planet, "Aquarius", "6mm Planetary", 200, 4, 3, 5),
            ("Hercules Cluster", .cluster, "Hercules", "9mm Wide", 133, 5, 4, 5),
            ("Albireo", .double, "Cygnus", "25mm Plössl", 48, 3, 4, 4),
            ("Ring Nebula", .nebula, "Lyra", "9mm Wide", 133, 4, 3, 3),
            ("Jupiter", .planet, "Taurus", "6mm Planetary", 200, 3, 2, 4)
        ]
        for (i, l) in logs.enumerated() {
            let o = Observation(
                date: cal.date(byAdding: .day, value: -(i * 6 + 1), to: .now) ?? .now,
                targetName: l.0, targetType: l.1, constellation: l.2,
                telescopeName: "8\" Dob", eyepieceName: l.3, magnification: l.4,
                location: i % 2 == 0 ? "Backyard" : "Dark site", bortle: i % 2 == 0 ? 6 : 3,
                seeing: l.5, transparency: l.6, rating: l.7,
                notes: i == 0 ? "Trapezium split cleanly tonight." : ""
            )
            context.insert(o)
        }
        try? context.save()
    }
}
