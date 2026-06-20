import SwiftUI

struct CurrencyField: View {
    let label: String
    @Binding var value: Decimal
    var currencyCode: String = "USD"

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0.00", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    if let parsed = parseCurrencyInput(newValue) {
                        value = parsed
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        if value == Decimal(0) { text = "" }
                    } else {
                        text = formatDecimalInput(value)
                    }
                }
                .onAppear {
                    text = value == Decimal(0) ? "" : formatDecimalInput(value)
                }
                .accessibilityLabel(label)
        }
    }

    private func formatDecimalInput(_ value: Decimal) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        return fmt.string(from: value as NSDecimalNumber) ?? "0.00"
    }
}
