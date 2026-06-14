import SwiftUI

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("currencySymbol") var currencySymbol: String = "$"
    @AppStorage("hideBalances") var hideBalances: Bool = false
    @AppStorage("defaultRollover") var defaultRollover: Bool = true

    /// Format a money amount with the chosen currency symbol and grouping.
    /// Negative values render with a leading minus before the symbol.
    func money(_ value: Double) -> String {
        let symbol = currencySymbol.isEmpty ? "$" : currencySymbol
        let negative = value < -0.005
        let magnitude = abs(value)
        let formatter = AppSettings.numberFormatter
        let number = formatter.string(from: NSNumber(value: magnitude)) ?? String(format: "%.2f", magnitude)
        return (negative ? "-" : "") + symbol + number
    }

    /// Money string, but masked dots when balances are hidden.
    func moneyMasked(_ value: Double) -> String {
        hideBalances ? maskString : money(value)
    }

    var maskString: String { "••••" }

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        return f
    }()
}
