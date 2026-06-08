import Foundation

enum Money {
    /// Formats an amount in the trip's currency, falling back gracefully.
    static func string(_ amount: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = (amount.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        return f.string(from: NSNumber(value: amount)) ?? "\(code) \(Int(amount))"
    }

    static func compact(_ amount: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}
