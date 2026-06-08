import Foundation

enum Money {
    static func string(_ amount: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = (amount.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        return f.string(from: NSNumber(value: amount)) ?? "\(code) \(Int(amount))"
    }
    static func precise(_ amount: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: amount)) ?? "\(code) \(amount)"
    }
}
