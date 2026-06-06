import Foundation

/// Builds CSV and JSON exports of sessions, attempts, and climbs. Pure string
/// builders so they're easy to reason about and never crash on user data.
enum Exporter {

    // MARK: - CSV

    /// Quote a field for CSV (RFC 4180): wrap in quotes and double any inner quotes.
    private static func csvField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// One row per attempt, flattened with its session and climb context. Grades
    /// are rendered in the user's preferred display systems.
    static func attemptsCSV(sessions: [Session],
                            boulderSystem: GradeSystem,
                            routeSystem: GradeSystem) -> String {
        var rows = ["session_date,location,duration_min,climb,discipline,grade,outcome,is_send,attempt_notes"]
        for session in sessions.sorted(by: { $0.date < $1.date }) {
            let date = isoFormatter.string(from: session.date)
            let location = session.location?.name ?? ""
            for attempt in session.orderedAttempts {
                let grade = attempt.gradeLabel(boulderSystem: boulderSystem, routeSystem: routeSystem)
                let discipline = attempt.climb?.discipline.title
                    ?? (attempt.gradeFamily == .boulder ? "Boulder" : "Route")
                let fields = [
                    csvField(date),
                    csvField(location),
                    csvField(String(session.durationMinutes)),
                    csvField(attempt.climbName),
                    csvField(discipline),
                    csvField(grade),
                    csvField(attempt.outcome.title),
                    csvField(attempt.outcome.isSend ? "yes" : "no"),
                    csvField(attempt.notes)
                ]
                rows.append(fields.joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n")
    }

    /// One row per climb.
    static func climbsCSV(climbs: [Climb],
                          boulderSystem: GradeSystem,
                          routeSystem: GradeSystem) -> String {
        var rows = ["name,discipline,grade,location,is_project,sends,notes"]
        for climb in climbs.sorted(by: { $0.createdAt < $1.createdAt }) {
            let grade = climb.gradeLabel(boulderSystem: boulderSystem, routeSystem: routeSystem)
            let fields = [
                csvField(climb.displayName),
                csvField(climb.discipline.title),
                csvField(grade),
                csvField(climb.location?.name ?? ""),
                csvField(climb.isProject ? "yes" : "no"),
                csvField(String(climb.sendCount)),
                csvField(climb.notes)
            ]
            rows.append(fields.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - JSON

    /// A Codable export envelope. Grades carry both the canonical index and the
    /// rendered labels so the export is both machine- and human-readable.
    struct Export: Codable {
        var generatedAt: Date
        var sessions: [SessionDTO]
        var climbs: [ClimbDTO]
    }

    struct SessionDTO: Codable {
        var date: Date
        var location: String?
        var durationMinutes: Int
        var notes: String
        var attempts: [AttemptDTO]
    }

    struct AttemptDTO: Codable {
        var order: Int
        var climb: String
        var family: String
        var gradeIndex: Int
        var grade: String
        var outcome: String
        var isSend: Bool
        var notes: String
    }

    struct ClimbDTO: Codable {
        var name: String
        var discipline: String
        var family: String
        var gradeIndex: Int
        var grade: String
        var location: String?
        var isProject: Bool
        var sends: Int
        var notes: String
    }

    /// Serialize the full logbook to pretty-printed JSON. Returns nil only if
    /// encoding somehow fails (it won't for these value types).
    static func json(sessions: [Session],
                     climbs: [Climb],
                     boulderSystem: GradeSystem,
                     routeSystem: GradeSystem) -> String? {
        let sessionDTOs = sessions.sorted(by: { $0.date < $1.date }).map { session in
            SessionDTO(
                date: session.date,
                location: session.location?.name,
                durationMinutes: session.durationMinutes,
                notes: session.notes,
                attempts: session.orderedAttempts.map { attempt in
                    AttemptDTO(
                        order: attempt.order,
                        climb: attempt.climbName,
                        family: attempt.gradeFamily.rawValue,
                        gradeIndex: attempt.gradeIndex,
                        grade: attempt.gradeLabel(boulderSystem: boulderSystem, routeSystem: routeSystem),
                        outcome: attempt.outcome.rawValue,
                        isSend: attempt.outcome.isSend,
                        notes: attempt.notes
                    )
                }
            )
        }
        let climbDTOs = climbs.sorted(by: { $0.createdAt < $1.createdAt }).map { climb in
            ClimbDTO(
                name: climb.displayName,
                discipline: climb.discipline.rawValue,
                family: climb.gradeFamily.rawValue,
                gradeIndex: climb.gradeIndex,
                grade: climb.gradeLabel(boulderSystem: boulderSystem, routeSystem: routeSystem),
                location: climb.location?.name,
                isProject: climb.isProject,
                sends: climb.sendCount,
                notes: climb.notes
            )
        }
        let export = Export(generatedAt: .now, sessions: sessionDTOs, climbs: climbDTOs)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(export) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
