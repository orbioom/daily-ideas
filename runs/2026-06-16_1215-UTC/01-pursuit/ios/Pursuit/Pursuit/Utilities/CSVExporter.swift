import Foundation

/// RFC-4180 compliant CSV export of the application pipeline.
enum CSVExporter {
    private static func escape(_ field: String) -> String {
        // A field must be quoted if it contains a comma, quote, CR or LF.
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return field
    }

    private static func decimalString(_ value: Decimal?) -> String {
        guard let value else { return "" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func dateString(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoDate.string(from: date)
    }

    static let headers = [
        "Company", "Role", "Location", "Work Mode", "Status",
        "Salary Min", "Salary Max", "Currency", "Source", "URL",
        "Applied Date", "Date Added", "Priority", "Excitement",
        "Tags", "Interviews", "Contacts", "Follow-up Date", "Notes"
    ]

    /// Build the full CSV text. Uses CRLF line endings per RFC-4180.
    static func makeCSV(from applications: [Application]) -> String {
        var rows: [String] = []
        rows.append(headers.map(escape).joined(separator: ","))

        for app in applications.sorted(by: { $0.dateAdded > $1.dateAdded }) {
            let tags = app.tags.map(\.name).sorted().joined(separator: "; ")
            let fields: [String] = [
                app.company,
                app.role,
                app.location,
                app.workMode.label,
                app.status.label,
                decimalString(app.salaryMin),
                decimalString(app.salaryMax),
                app.currencyCode,
                app.source.label,
                app.urlString,
                dateString(app.appliedDate),
                dateString(app.dateAdded),
                app.priority.label,
                String(app.excitement),
                tags,
                String(app.interviews.count),
                String(app.contacts.count),
                dateString(app.followUpEnabled ? app.followUpDate : nil),
                app.notes
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\r\n")
    }

    /// Write the CSV to a temporary file and return its URL, or nil on failure.
    static func writeTempFile(from applications: [Application]) -> URL? {
        let csv = makeCSV(from: applications)
        let name = "Pursuit-Export-\(isoDate.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
