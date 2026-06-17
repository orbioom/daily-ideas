import Foundation

/// CSV export of completed sessions (a Pro feature). Writes a temp file for the
/// share sheet. All fields are escaped.
enum CSVExport {

    static func sessionsCSV(_ sessions: [CompletedSession], units: DistanceUnit) -> String {
        var rows = ["Date,Plan,Week,Session,Duration (min),Run (min),Felt (1-5),Distance (\(units.label))"]
        let sorted = sessions.sorted { $0.date < $1.date }
        for s in sorted {
            let date = Fmt.longDate(s.date)
            let dur = String(format: "%.1f", Double(s.durationSeconds) / 60.0)
            let run = String(format: "%.1f", Double(s.runSeconds) / 60.0)
            let felt = s.feltRating.map(String.init) ?? ""
            let dist = s.distanceMeters.map { String(format: "%.2f", units.fromMeters($0)) } ?? ""
            let plan = PlanResolver.shared.plan(id: s.planId)?.title ?? s.planId
            let cols = [date, plan, "\(s.week)", "\(s.sessionIndex + 1)", dur, run, felt, dist]
            rows.append(cols.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    /// Write CSV to a temp file; returns its URL or nil on failure.
    static func writeTempFile(named name: String, contents: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
