import Foundation

extension Collection {
    /// Safe subscript: returns nil instead of trapping on an out-of-range index.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Decimal {
    /// Rounds to `places` decimal places using plain rounding (currency-safe).
    func rounded(_ places: Int = 2) -> Decimal {
        var result = Decimal()
        var copy = self
        NSDecimalRound(&result, &copy, places, .plain)
        return result
    }

    /// Double bridge used only for charting / non-money display. Never for money math.
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
