import Foundation

/// Builds a CSV export of all readings (always in canonical mg/dL plus mmol/L).
enum CSVExporter {

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let inner = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(inner)\""
        }
        return field
    }

    /// One row per reading, most recent first.
    static func build(readings: [Reading]) -> String {
        var lines: [String] = []
        lines.append("Date,Time,Value (mg/dL),Value (mmol/L),Context,Carbs (g),Insulin (U),Note")

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        for r in readings.sorted(by: { $0.date > $1.date }) {
            let mmol = String(format: "%.1f", GlucoseEngine.mmol(from: r.valueMgdl))
            let carbs = r.carbs.map { String(format: "%.0f", $0) } ?? ""
            let insulin = r.insulinUnits.map { String(format: "%.1f", $0) } ?? ""
            let row = [
                dateFmt.string(from: r.date),
                timeFmt.string(from: r.date),
                String(format: "%.0f", r.valueMgdl),
                mmol,
                r.context.label,
                carbs,
                insulin,
                r.note
            ].map(escape).joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    /// A document wrapper so the CSV can be shared via ShareLink.
    static func temporaryFileURL(contents: String) -> URL? {
        let name = "Lancet-Readings-\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
