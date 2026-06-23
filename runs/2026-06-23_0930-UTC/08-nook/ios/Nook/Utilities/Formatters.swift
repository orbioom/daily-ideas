import Foundation

enum Formatters {
    static func date(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    static func currency(_ amount: Double, code: String) -> String {
        let safe = amount.isFinite ? amount : 0
        return safe.formatted(.currency(code: code).precision(.fractionLength(0...2)))
    }

    static func minutes(_ m: Int) -> String {
        guard m > 0 else { return "—" }
        if m < 60 { return "\(m) min" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h) hr" : "\(h)h \(rem)m"
    }
}
