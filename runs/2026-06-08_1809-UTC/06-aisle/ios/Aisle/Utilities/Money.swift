import Foundation

enum Money {
    static func format(_ value: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = abs(value) >= 1000 ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
    static func compact(_ value: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
}
