import Foundation
import SwiftUI

enum Currency {
    static var code: String { UserDefaults.standard.string(forKey: "currencyCode") ?? Locale.current.currency?.identifier ?? "USD" }
    static func string(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

enum Fmt {
    static func hours(_ h: Double) -> String {
        if h <= 0 { return "0h" }
        if h < 1 { return String(format: "%.0fm", h * 60) }
        if h.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(h))h" }
        return String(format: "%.1fh", h)
    }
    static func date(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
}

/// Stable cover swatch gradient from a game's hue.
extension Game {
    var coverGradient: LinearGradient {
        let base = Color(hue: coverHue, saturation: 0.55, brightness: 0.72)
        let deep = Color(hue: (coverHue + 0.08).truncatingRemainder(dividingBy: 1), saturation: 0.62, brightness: 0.5)
        return LinearGradient(colors: [base, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var initials: String {
        let words = title.split(separator: " ").prefix(2)
        let chars = words.compactMap { $0.first }
        return String(chars).uppercased()
    }
}
