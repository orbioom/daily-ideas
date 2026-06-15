import SwiftUI

/// A money figure that respects the hide-balances privacy mode. When hidden it shows a
/// neutral dotted mask of similar width so layout stays stable.
struct MoneyText: View {
    let value: Decimal
    var code: String = "USD"
    var compact: Bool = false
    var perShare: Bool = false
    var hidden: Bool = false
    var font: Font = Theme.rounded(17, .semibold)
    var color: Color = Theme.ink

    private var text: String {
        if perShare { return MoneyFormat.perShare(value, code: code) }
        if compact { return MoneyFormat.currencyCompact(value, code: code) }
        return MoneyFormat.currency(value, code: code)
    }

    var body: some View {
        Text(hidden ? "••••" : text)
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .accessibilityLabel(hidden ? "Balance hidden" : text)
    }
}
