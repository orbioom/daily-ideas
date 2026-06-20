import Foundation
import SwiftData

struct DojoSeeder {
    static func seed(ctx: ModelContext) {
        let techniques: [(name: String, category: TechniqueCategory)] = [
            // Guard
            ("Closed Guard", .guard_),
            ("Open Guard", .guard_),
            ("Half Guard", .guard_),
            ("Butterfly Guard", .guard_),
            ("Spider Guard", .guard_),

            // Guard Passes
            ("Torreando Pass", .guardPasses),
            ("Leg Drag Pass", .guardPasses),
            ("Knee Slice Pass", .guardPasses),
            ("Double Under Pass", .guardPasses),
            ("Headquarters Pass", .guardPasses),

            // Submissions
            ("Rear Naked Choke", .submissions),
            ("Triangle Choke", .submissions),
            ("Armbar", .submissions),
            ("Kimura", .submissions),
            ("Guillotine", .submissions),
            ("Americana", .submissions),
            ("Heel Hook", .submissions),
            ("Ankle Lock", .submissions),
            ("Bow and Arrow Choke", .submissions),
            ("D'Arce Choke", .submissions),

            // Sweeps
            ("Scissor Sweep", .sweeps),
            ("Hip Bump Sweep", .sweeps),
            ("Flower Sweep", .sweeps),
            ("Tripod Sweep", .sweeps),
            ("Sickle Sweep", .sweeps),

            // Takedowns
            ("Double Leg Takedown", .takedowns),
            ("Single Leg Takedown", .takedowns),
            ("Osoto Gari", .takedowns),
            ("Seoi Nage", .takedowns),

            // Back Control
            ("Back Take", .back),
            ("Seatbelt Control", .back),
            ("Body Triangle", .back),

            // Escapes
            ("Bridge and Roll", .escapes),
            ("Elbow-Knee Escape", .escapes),
            ("Turtle Defense", .escapes)
        ]

        let seededDate = Date(timeIntervalSinceNow: -86400 * 30) // 30 days ago

        for (name, category) in techniques {
            let technique = Technique(
                name: name,
                category: category.rawValue,
                notes: "",
                isFavorite: false,
                drillCount: 0,
                addedDate: seededDate
            )
            ctx.insert(technique)
        }

        // Seed initial white belt record
        let whiteBelt = BeltRecord(
            belt: BjjBelt.white.rawValue,
            stripes: 0,
            awardedDate: seededDate,
            instructor: "",
            notes: "Starting rank"
        )
        ctx.insert(whiteBelt)

        do {
            try ctx.save()
        } catch {
            print("DojoSeeder save error: \(error)")
        }
    }
}
