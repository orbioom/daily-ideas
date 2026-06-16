import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// A CSV file wrapped for ShareLink export.
struct CSVDocument: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { doc in
            Data(doc.text.utf8)
        }
        .suggestedFileName("encore-export.csv")
    }
}

/// Builds a CSV of the full concert log.
enum CSVExport {
    @MainActor
    static func build(concerts: [Concert], settings: AppSettings) -> String {
        let header = ["Headliner", "Date", "Venue", "City", "Country", "Tour",
                      "Status", "Type", "Rating", "Price", "Currency", "Seat",
                      "Companions", "Genres", "SupportActs", "SetlistCount", "Favorite", "Notes"]
        var rows: [String] = [header.map(escape).joined(separator: ",")]

        let sorted = concerts.sorted { $0.date > $1.date }
        for c in sorted {
            let priceString = c.ticketPrice == 0
                ? ""
                : NSDecimalNumber(decimal: c.ticketPrice).stringValue
            let genres = c.sortedGenres.map { $0.name }.joined(separator: "; ")
            let support = c.orderedSupportActs.map { $0.name }.joined(separator: "; ")
            let fields: [String] = [
                c.headliner,
                isoDate(c.date),
                c.venueName,
                c.city,
                c.country,
                c.tourName,
                c.status.rawValue,
                c.type.rawValue,
                c.rating.map { String(format: "%.1f", $0) } ?? "",
                priceString,
                priceString.isEmpty ? "" : settings.currencyCode,
                c.seatInfo,
                c.companions,
                genres,
                support,
                String(c.setlist.count),
                c.isFavorite ? "Yes" : "No",
                c.notes.replacingOccurrences(of: "\n", with: " ")
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// RFC-4180 quoting: wrap in quotes if it contains comma, quote, or newline.
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
