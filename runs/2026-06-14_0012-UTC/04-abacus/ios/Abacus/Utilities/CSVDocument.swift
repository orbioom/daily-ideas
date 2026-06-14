import SwiftUI
import UniformTypeIdentifiers

/// A simple, dependency-free CSV file wrapper for `ShareLink` / file export.
struct CSVDocument: Transferable {
    let text: String
    let suggestedName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { doc in
            Data(doc.text.utf8)
        }
        .suggestedFileName { $0.suggestedName }
    }
}

enum CSVBuilder {
    /// Build an amortization-schedule CSV. Values are rounded to cents for export.
    static func amortization(rows: [AmortRow], symbol: String) -> String {
        var lines: [String] = ["Month,Date,Payment,Principal,Interest,Extra,Balance"]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for row in rows {
            let cols = [
                String(row.month),
                df.string(from: row.date),
                round2(row.payment),
                round2(row.principal),
                round2(row.interest),
                round2(row.extra),
                round2(row.balance)
            ]
            lines.append(cols.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func round2(_ v: Double) -> String {
        let x = v.isFinite ? v : 0
        return String(format: "%.2f", x)
    }
}
