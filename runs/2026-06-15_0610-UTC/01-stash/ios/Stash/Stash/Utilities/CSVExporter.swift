import Foundation

/// Builds CSV text for loyalty + gift cards and writes it to a temporary file for
/// sharing. A Pro feature. Pure string work — no force-unwraps.
enum CSVExporter {

    /// Escape a field for CSV (wrap in quotes, double internal quotes).
    private static func field(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func dateString(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoFormatter.string(from: date)
    }

    /// Build a CSV string covering all loyalty and gift cards.
    static func makeCSV(loyalty: [LoyaltyCard], gift: [GiftCard]) -> String {
        var lines: [String] = []

        lines.append("Type,Name,Store,Code,Format,Category,InitialBalance,Remaining,Currency,Expiry,Favorite,Notes,Created,LastUsed")

        for card in loyalty {
            let row = [
                field("Loyalty"),
                field(card.name),
                field(card.storeName),
                field(card.codeValue),
                field(card.format.displayName),
                field(card.category.displayName),
                field(""),
                field(""),
                field(""),
                field(""),
                field(card.isFavorite ? "Yes" : "No"),
                field(card.notes),
                field(dateString(card.createdAt)),
                field(dateString(card.lastUsedAt))
            ].joined(separator: ",")
            lines.append(row)
        }

        for card in gift {
            let row = [
                field("Gift"),
                field(""),
                field(card.storeName),
                field(card.code),
                field(card.format.displayName),
                field(""),
                field(Money.string(card.initialBalance, code: card.currencyCode)),
                field(Money.string(card.remainingBalance, code: card.currencyCode)),
                field(card.currencyCode),
                field(dateString(card.expiryDate)),
                field(""),
                field(card.notes),
                field(dateString(card.createdAt)),
                field("")
            ].joined(separator: ",")
            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }

    /// Write the CSV to a temporary file and return its URL for a share sheet.
    static func writeTempFile(_ csv: String) -> URL? {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("Stash-Export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
