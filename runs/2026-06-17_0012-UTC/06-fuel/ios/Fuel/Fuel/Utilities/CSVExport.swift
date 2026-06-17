import Foundation

/// Builds CSV text for the user's check-ins and target log (Pro feature).
enum CSVExport {

    static func checkInsCSV(_ checkIns: [CheckIn], unit: WeightUnit) -> String {
        var rows = ["date,weight_\(unit.label),avg_intake_kcal,note"]
        for c in checkIns.sorted(by: { $0.date < $1.date }) {
            let date = isoFormatter.string(from: c.date)
            let w = String(format: "%.2f", unit.fromKg(c.weightKg))
            let intake = c.avgDailyIntakeKcal.map { String(Int($0.rounded())) } ?? ""
            let note = escape(c.note)
            rows.append("\(date),\(w),\(intake),\(note)")
        }
        return rows.joined(separator: "\n")
    }

    static func targetsCSV(_ snapshots: [TargetSnapshot]) -> String {
        var rows = ["date,calorie_target,protein_g,carb_g,fat_g,estimated_tdee,rationale"]
        for s in snapshots.sorted(by: { $0.date < $1.date }) {
            let date = isoFormatter.string(from: s.date)
            rows.append("\(date),\(Int(s.calorieTarget.rounded())),\(Int(s.proteinG.rounded())),\(Int(s.carbG.rounded())),\(Int(s.fatG.rounded())),\(Int(s.estimatedTDEE.rounded())),\(escape(s.rationale))")
        }
        return rows.joined(separator: "\n")
    }

    /// Write a CSV string to a temporary file and return its URL for sharing.
    static func writeTempFile(named name: String, contents: String) -> URL? {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(name)
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else { return field }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}
