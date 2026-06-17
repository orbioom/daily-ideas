import Foundation

/// Builds a CSV string from all entries. Pure and side-effect free; the caller
/// is responsible for presenting/sharing the resulting file.
enum CSVExporter {
    static func makeCSV(sites: [MeasurementSite], entries: [MeasurementEntry], system: UnitSystem) -> String {
        let nameByKey = Dictionary(uniqueKeysWithValues: sites.map { ($0.key, $0) })
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        var lines = ["date,site,value,unit"]
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let dateStr = formatter.string(from: entry.date)
            let site = nameByKey[entry.siteKey]
            let kind = site?.unitKind ?? .length
            let name = (site?.name ?? entry.siteKey)
            let value = Units.displayValue(canonical: entry.valueCanonical, kind: kind, system: system)
            let unit = Units.unitLabel(kind: kind, system: system)
            let safeName = name.contains(",") ? "\"\(name)\"" : name
            lines.append("\(dateStr),\(safeName),\(Units.number(value, digits: 2)),\(unit)")
        }
        return lines.joined(separator: "\n")
    }

    /// Writes the CSV to a temporary file and returns its URL, or nil on failure.
    static func writeTempFile(_ csv: String) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Caliper-export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
