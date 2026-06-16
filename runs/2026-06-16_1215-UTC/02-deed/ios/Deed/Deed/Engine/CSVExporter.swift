import Foundation

/// RFC-4180 compliant CSV generation for transactions and rent roll.
enum CSVExporter {

    /// Escapes a field per RFC 4180: wrap in quotes if it contains comma, quote, CR or LF; double internal quotes.
    static func escape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
        if needsQuoting {
            let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return field
    }

    static func row(_ fields: [String]) -> String {
        fields.map(escape).joined(separator: ",")
    }

    /// Plain decimal string (no currency symbol/grouping) for spreadsheet import.
    static func amountString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let rounded = Money.round(value, scale: 2)
        return formatter.string(from: rounded as NSDecimalNumber) ?? "0.00"
    }

    static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func transactionsCSV(for properties: [Property]) -> String {
        var lines: [String] = []
        lines.append(row(["Date", "Property", "Kind", "Category", "Amount", "Notes"]))

        let sorted = properties
            .flatMap { property in property.transactions.map { (property, $0) } }
            .sorted { $0.1.date > $1.1.date }

        for (property, txn) in sorted {
            lines.append(row([
                isoDate.string(from: txn.date),
                property.name,
                txn.kind.rawValue,
                txn.category.rawValue,
                amountString(txn.amount),
                txn.notes
            ]))
        }
        // RFC 4180 uses CRLF line breaks.
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    static func rentRollCSV(for properties: [Property]) -> String {
        var lines: [String] = []
        lines.append(row(["Property", "Unit", "Tenant", "Due Date", "Amount Due", "Amount Paid", "Status", "Paid Date"]))

        var records: [(date: Date, fields: [String])] = []
        for property in properties {
            for unit in property.units {
                for lease in unit.leases {
                    for payment in lease.payments {
                        let paidDateString = payment.paidDate.map { isoDate.string(from: $0) } ?? ""
                        records.append((
                            payment.dueDate,
                            [
                                property.name,
                                unit.label,
                                lease.tenantName,
                                isoDate.string(from: payment.dueDate),
                                amountString(payment.amountDue),
                                amountString(payment.amountPaid),
                                payment.status.rawValue,
                                paidDateString
                            ]
                        ))
                    }
                }
            }
        }
        for record in records.sorted(by: { $0.date > $1.date }) {
            lines.append(row(record.fields))
        }
        return lines.joined(separator: "\r\n") + "\r\n"
    }
}

/// Wraps CSV text as a transferable file for ShareLink.
import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: Transferable {
    let text: String
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { document in
            Data(document.text.utf8)
        }
        .suggestedFileName { $0.filename }
    }
}
