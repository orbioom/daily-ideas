import Foundation

/// Serializes the inventory to CSV or JSON for export/share. Pure string building —
/// no file system writes here; the caller hands the text to a share sheet.
enum InventoryExport {

    enum Format: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        var id: String { rawValue }
        var fileExtension: String { self == .csv ? "csv" : "json" }
    }

    /// A flattened, UI-agnostic snapshot of one item for export.
    struct Record {
        var name: String
        var category: String
        var location: String
        var quantity: Double
        var unit: String
        var purchaseDate: Date?
        var expiryDate: Date?
        var lowStockThreshold: Double
        var notes: String
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    private static func dateString(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoFormatter.string(from: date)
    }

    private static func numberString(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%g", value)
    }

    // MARK: - CSV

    /// Escapes a field for CSV: wraps in quotes and doubles embedded quotes when needed.
    private static func csvField(_ raw: String) -> String {
        let needsQuoting = raw.contains(",") || raw.contains("\"")
            || raw.contains("\n") || raw.contains("\r")
        guard needsQuoting else { return raw }
        let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    static func csv(from records: [Record]) -> String {
        let header = ["Name", "Category", "Location", "Quantity", "Unit",
                      "Purchase Date", "Expiry Date", "Low Stock Threshold", "Notes"]
        var lines = [header.joined(separator: ",")]
        for r in records {
            let row = [
                csvField(r.name),
                csvField(r.category),
                csvField(r.location),
                numberString(r.quantity),
                csvField(r.unit),
                dateString(r.purchaseDate),
                dateString(r.expiryDate),
                numberString(r.lowStockThreshold),
                csvField(r.notes)
            ]
            lines.append(row.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - JSON

    static func json(from records: [Record]) -> String {
        let objects: [[String: Any]] = records.map { r in
            [
                "name": r.name,
                "category": r.category,
                "location": r.location,
                "quantity": r.quantity,
                "unit": r.unit,
                "purchaseDate": dateString(r.purchaseDate),
                "expiryDate": dateString(r.expiryDate),
                "lowStockThreshold": r.lowStockThreshold,
                "notes": r.notes
            ]
        }
        let payload: [String: Any] = [
            "app": "Larder",
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "itemCount": records.count,
            "items": objects
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(
                withJSONObject: payload,
                options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            return "{\n  \"app\" : \"Larder\",\n  \"items\" : []\n}"
        }
        return text
    }
}
