import Foundation

/// Builds plain-text export payloads (CSV / JSON) for a formula or a bake. Pure string
/// assembly — no file I/O here; the view writes the result to a temp file for sharing.
enum Exporter {

    // MARK: - CSV escaping

    private static func csvField(_ raw: String) -> String {
        let needsQuoting = raw.contains(",") || raw.contains("\"") || raw.contains("\n")
        let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuoting ? "\"\(escaped)\"" : escaped
    }

    private static func csvRow(_ fields: [String]) -> String {
        fields.map(csvField).joined(separator: ",")
    }

    // MARK: - Formula CSV

    /// A solved formula as CSV: one row per ingredient plus headline totals.
    static func formulaCSV(_ formula: Formula, result: BakersMath.Result, massUnit: Units.Mass) -> String {
        var lines: [String] = []
        lines.append(csvRow(["Formula", formula.name]))
        lines.append(csvRow(["Style", formula.style.title]))
        lines.append(csvRow(["Total dough (\(massUnit.suffix))",
                              Units.mass(result.totalDoughGrams, unit: massUnit)]))
        lines.append(csvRow(["Hydration (%)", BakersMath.displayPercent(result.hydrationPercent)]))
        lines.append(csvRow(["Salt (%)", BakersMath.displayPercent(result.saltPercent)]))
        lines.append(csvRow(["Levain (%)", BakersMath.displayPercent(result.levainPercent)]))
        lines.append("")
        lines.append(csvRow(["Ingredient", "Role", "Baker's %", "Weight (\(massUnit.suffix))"]))
        for row in result.rows {
            lines.append(csvRow([row.name, row.role.title,
                                 BakersMath.displayPercent(row.percent),
                                 Units.mass(row.grams, unit: massUnit)]))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Formula JSON

    static func formulaJSON(_ formula: Formula, result: BakersMath.Result, massUnit: Units.Mass) -> String {
        let rows: [[String: Any]] = result.rows.map { row in
            [
                "name": row.name,
                "role": row.role.rawValue,
                "bakersPercent": round(row.percent * 100) / 100,
                "grams": round(row.grams * 100) / 100
            ]
        }
        let payload: [String: Any] = [
            "name": formula.name,
            "style": formula.style.rawValue,
            "notes": formula.notes,
            "totalDoughGrams": round(result.totalDoughGrams * 100) / 100,
            "hydrationPercent": round(result.hydrationPercent * 100) / 100,
            "saltPercent": round(result.saltPercent * 100) / 100,
            "levainPercent": round(result.levainPercent * 100) / 100,
            "massUnit": massUnit.rawValue,
            "ingredients": rows
        ]
        return jsonString(from: payload)
    }

    // MARK: - Bake CSV

    static func bakeCSV(_ bake: Bake, scheduled: [BakersMath.ScheduledStep],
                        tempUnit: Units.Temperature, massUnit: Units.Mass) -> String {
        var lines: [String] = []
        lines.append(csvRow(["Bake", bake.title]))
        lines.append(csvRow(["Formula", bake.formula?.name ?? "—"]))
        lines.append(csvRow(["Date", Self.dateFormatter.string(from: bake.date)]))
        lines.append(csvRow(["Target dough (\(massUnit.suffix))",
                              Units.mass(bake.targetDoughGrams, unit: massUnit)]))
        lines.append(csvRow(["Loaves", String(bake.loafCount)]))
        lines.append(csvRow(["Oven", Units.temperature(bake.ovenTempC, unit: tempUnit)]))
        if bake.crumbRating > 0 {
            lines.append(csvRow(["Crumb rating", "\(bake.crumbRating)/5"]))
        }
        lines.append("")
        lines.append(csvRow(["Step", "Planned", "Start", "End"]))
        for step in scheduled {
            lines.append(csvRow([step.label,
                                 BakersMath.durationString(minutes: step.plannedMinutes),
                                 Self.timeFormatter.string(from: step.start),
                                 Self.timeFormatter.string(from: step.end)]))
        }
        if !bake.notes.isEmpty {
            lines.append("")
            lines.append(csvRow(["Notes", bake.notes]))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Bake JSON

    static func bakeJSON(_ bake: Bake, scheduled: [BakersMath.ScheduledStep]) -> String {
        let steps: [[String: Any]] = scheduled.map { step in
            [
                "label": step.label,
                "kind": step.kind.rawValue,
                "plannedMinutes": step.plannedMinutes,
                "start": Self.isoFormatter.string(from: step.start),
                "end": Self.isoFormatter.string(from: step.end)
            ]
        }
        var payload: [String: Any] = [
            "title": bake.title,
            "formula": bake.formula?.name ?? "",
            "date": Self.isoFormatter.string(from: bake.date),
            "targetDoughGrams": round(bake.targetDoughGrams * 100) / 100,
            "loafCount": bake.loafCount,
            "ovenTempC": round(bake.ovenTempC * 100) / 100,
            "crumbRating": bake.crumbRating,
            "notes": bake.notes,
            "steps": steps
        ]
        if bake.doughTempC.isFinite {
            payload["doughTempC"] = round(bake.doughTempC * 100) / 100
        }
        return jsonString(from: payload)
    }

    // MARK: - JSON serialization

    private static func jsonString(from object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object,
                                                     options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    // MARK: - Formatters

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
