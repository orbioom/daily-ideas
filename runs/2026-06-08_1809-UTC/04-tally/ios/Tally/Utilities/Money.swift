import Foundation

enum Money {
    static func format(_ value: Double, code: String, showSign: Bool = false) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = abs(value) >= 100000 ? 0 : 2
        let base = f.string(from: NSNumber(value: abs(value))) ?? String(format: "%.2f", abs(value))
        if showSign { return (value < 0 ? "-" : "+") + base }
        return (value < 0 ? "-" : "") + base
    }

    static func compact(_ value: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
}
