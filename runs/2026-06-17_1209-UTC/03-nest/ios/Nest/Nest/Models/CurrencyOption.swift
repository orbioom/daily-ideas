import Foundation

/// A selectable currency (code + display symbol).
struct CurrencyOption: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let symbol: String
    let name: String

    static let all: [CurrencyOption] = [
        CurrencyOption(code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyOption(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyOption(code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyOption(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        CurrencyOption(code: "CAD", symbol: "$", name: "Canadian Dollar"),
        CurrencyOption(code: "AUD", symbol: "$", name: "Australian Dollar"),
        CurrencyOption(code: "INR", symbol: "₹", name: "Indian Rupee"),
        CurrencyOption(code: "BRL", symbol: "R$", name: "Brazilian Real")
    ]

    static func option(forCode code: String) -> CurrencyOption {
        all.first { $0.code == code } ?? all[0]
    }
}
