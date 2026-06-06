import Foundation
import SwiftData

/// Real, on-brand seed content so a first launch is a populated, realistic logbook —
/// not a void. Inserted once (gated by SettingsStore.hasSeeded) and reused by
/// "Reset to sample" in Settings. Always inserts into an empty store only.
enum SampleData {

    static func insert(into context: ModelContext) {
        // MARK: Locations
        let summit = Location(name: "Summit Boulders", kind: .gym,
                              createdAt: daysAgo(80))
        let vertex = Location(name: "Vertex Climbing", kind: .gym,
                              createdAt: daysAgo(78))
        let buttermilks = Location(name: "The Buttermilks", kind: .crag,
                                   createdAt: daysAgo(40))
        let redRiver = Location(name: "Red River Gorge", kind: .crag,
                                createdAt: daysAgo(20))
        for loc in [summit, vertex, buttermilks, redRiver] { context.insert(loc) }

        // MARK: Climbs (boulders + routes; a few projects)
        // Boulder grade indices are positions on the V/Font ladder (0 == V0).
        let blueSlab = climb(context, name: "Blue Slab", discipline: .boulder,
                             grade: 3, color: 0, location: summit, daysAgo: 70,
                             notes: "Balancey feet, no hands rest at the top.")
        let crimpLadder = climb(context, name: "Crimp Ladder", discipline: .boulder,
                                grade: 5, color: 6, location: summit, daysAgo: 60)
        let theArete = climb(context, name: "The Arête", discipline: .boulder,
                             grade: 6, color: 3, location: vertex, daysAgo: 55,
                             notes: "Tension-y arête, heel hook crux.")
        let dyno = climb(context, name: "Moonwalk Dyno", discipline: .boulder,
                         grade: 7, color: 1, location: vertex, daysAgo: 30,
                         isProject: true, notes: "Big move to the jug — still spitting me off.")
        let highball = climb(context, name: "Iron Man Traverse", discipline: .boulder,
                             grade: 8, location: buttermilks, daysAgo: 38,
                             isProject: true, notes: "Classic traverse. Skin destroyer.")
        // Routes (YDS/French ladder; 0 == 5.6).
        let warmupRoute = climb(context, name: "Easy Layback", discipline: .sport,
                                grade: 4, location: redRiver, daysAgo: 18)
        let pocketRoute = climb(context, name: "Pocket Symphony", discipline: .sport,
                                grade: 8, location: redRiver, daysAgo: 16,
                                notes: "Sustained pockets, no rest until the chains.")
        let topRopeRoute = climb(context, name: "Slabtastic", discipline: .topRope,
                                 grade: 6, location: vertex, daysAgo: 50)
        let tradLine = climb(context, name: "Hand Crack Heaven", discipline: .trad,
                             grade: 5, location: buttermilks, daysAgo: 35,
                             notes: "Bomber gear, sustained hands.")
        let projectRoute = climb(context, name: "Golden Ticket", discipline: .sport,
                                 grade: 12, location: redRiver, daysAgo: 14,
                                 isProject: true, notes: "Hardest thing I've touched. Working the redpoint crux.")

        // MARK: Sessions (across ~2.5 months, 20+ attempts total)

        // Session 1 — early indoor boulder day (~75 days ago)
        let s1 = session(context, daysAgo: 75, minutes: 95, location: summit,
                         notes: "First session back after a trip. Felt rusty but good.")
        attempt(context, s1, 0, .flash, blueSlab)
        attempt(context, s1, 1, .redpoint, crimpLadder)
        attempt(context, s1, 2, .fall, theArete)
        attempt(context, s1, 3, .redpoint, theArete)

        // Session 2 — indoor at Vertex (~60 days ago)
        let s2 = session(context, daysAgo: 60, minutes: 110, location: vertex,
                         notes: "Worked the arête, finally stuck the heel hook.")
        attempt(context, s2, 0, .flash, blueSlab)
        attempt(context, s2, 1, .flash, crimpLadder)
        attempt(context, s2, 2, .redpoint, theArete)
        attempt(context, s2, 3, .repeat, theArete)
        attempt(context, s2, 4, .fall, dyno)
        attempt(context, s2, 5, .fall, dyno)

        // Session 3 — outdoor crag trip, Buttermilks (~38 days ago)
        let s3 = session(context, daysAgo: 38, minutes: 240, location: buttermilks,
                         notes: "Cold, perfect friction. Long approach.")
        attempt(context, s3, 0, .onsight, tradLine)
        attempt(context, s3, 1, .fall, highball)
        attempt(context, s3, 2, .fall, highball)
        attempt(context, s3, 3, .fall, highball)

        // Session 4 — indoor strength day (~30 days ago)
        let s4 = session(context, daysAgo: 30, minutes: 80, location: vertex,
                         notes: "Short session, projecting the dyno.")
        attempt(context, s4, 0, .repeat, crimpLadder)
        attempt(context, s4, 1, .fall, dyno)
        attempt(context, s4, 2, .redpoint, dyno)
        attempt(context, s4, 3, .redpoint, theArete)

        // Session 5 — Red River Gorge sport day (~16 days ago)
        let s5 = session(context, daysAgo: 16, minutes: 300, location: redRiver,
                         notes: "Endurance day. Pumped silly.")
        attempt(context, s5, 0, .onsight, warmupRoute)
        attempt(context, s5, 1, .redpoint, pocketRoute)
        attempt(context, s5, 2, .fall, projectRoute)
        attempt(context, s5, 3, .fall, projectRoute)

        // Session 6 — most recent, mixed indoor (~4 days ago)
        let s6 = session(context, daysAgo: 4, minutes: 120, location: vertex,
                         notes: "Feeling strong. New PB attempt soon.")
        attempt(context, s6, 0, .flash, topRopeRoute)
        attempt(context, s6, 1, .repeat, theArete)
        attempt(context, s6, 2, .redpoint, dyno)
        attempt(context, s6, 3, .fall, highball)
        attempt(context, s6, 4, .onsight, blueSlab)
    }

    /// Remove every record (sessions cascade their attempts; climbs/locations cleared explicitly).
    static func clear(_ context: ModelContext) throws {
        for s in try context.fetch(FetchDescriptor<Session>()) { context.delete(s) }
        for c in try context.fetch(FetchDescriptor<Climb>()) { context.delete(c) }
        for l in try context.fetch(FetchDescriptor<Location>()) { context.delete(l) }
    }

    // MARK: - Builders

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    @discardableResult
    private static func climb(_ context: ModelContext,
                              name: String,
                              discipline: Discipline,
                              grade: Int,
                              color: Int = -1,
                              location: Location,
                              daysAgo days: Int,
                              isProject: Bool = false,
                              notes: String = "") -> Climb {
        // Snap grade into bounds so seed data can never reference an invalid rung.
        let bounded = GradeScale.clampedIndex(grade, family: discipline.family) ?? 0
        let c = Climb(name: name, discipline: discipline, gradeIndex: bounded,
                      colorIndex: color, setDate: daysAgo(days), notes: notes,
                      isProject: isProject, createdAt: daysAgo(days), location: location)
        context.insert(c)
        location.climbs.append(c)
        return c
    }

    @discardableResult
    private static func session(_ context: ModelContext,
                                daysAgo days: Int,
                                minutes: Int,
                                location: Location,
                                notes: String) -> Session {
        let date = daysAgo(days)
        let s = Session(date: date, durationMinutes: minutes, notes: notes,
                        createdAt: date, location: location)
        context.insert(s)
        location.sessions.append(s)
        return s
    }

    private static func attempt(_ context: ModelContext,
                                _ session: Session,
                                _ order: Int,
                                _ outcome: Outcome,
                                _ climb: Climb) {
        let a = Attempt(order: order, outcome: outcome,
                        gradeFamily: climb.gradeFamily, gradeIndex: climb.gradeIndex,
                        createdAt: session.date, climb: climb)
        a.session = session
        session.attempts.append(a)
        context.insert(a)
    }
}
