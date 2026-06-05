import Foundation

/// A small currency descriptor used for new groups and formatting. Stored on a group
/// as its ISO-style code; formatting always uses the matching symbol and 2 minor digits.
struct Currency: Identifiable, Hashable {
    let code: String
    let symbol: String
    let name: String

    var id: String { code }

    /// The supported set offered when creating a group / in Settings.
    static let all: [Currency] = [
        Currency(code: "USD", symbol: "$",  name: "US Dollar"),
        Currency(code: "EUR", symbol: "€",  name: "Euro"),
        Currency(code: "GBP", symbol: "£",  name: "British Pound"),
        Currency(code: "JPY", symbol: "¥",  name: "Japanese Yen"),
        Currency(code: "INR", symbol: "₹",  name: "Indian Rupee"),
        Currency(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
        Currency(code: "AUD", symbol: "A$", name: "Australian Dollar"),
        Currency(code: "CHF", symbol: "CHF", name: "Swiss Franc")
    ]

    static func symbol(for code: String) -> String {
        all.first { $0.code == code }?.symbol ?? code
    }

    static func named(_ code: String) -> Currency {
        all.first { $0.code == code } ?? all[0]
    }
}
