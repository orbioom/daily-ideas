import SwiftUI

/// A labelled numeric input row with a leading symbol/affix and a decimal keypad.
/// Binds to a `Double` via a string proxy so partial edits never crash.
struct CurrencyField: View {
    let title: String
    let symbol: String
    @Binding var value: Double
    var accessibilityHint: String? = nil

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        FieldShell(title: title, leading: symbol) {
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .focused($focused)
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
                .onAppear { syncFromValue() }
                .onChange(of: focused) { _, isFocused in
                    if !isFocused { syncFromValue() }
                }
                .onChange(of: text) { _, newValue in
                    let cleaned = clean(newValue)
                    if cleaned != newValue { text = cleaned }
                    value = Double(cleaned) ?? 0
                }
                .onChange(of: value) { _, _ in
                    if !focused { syncFromValue() }
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(Fmt.money(value, symbol: symbol))
        .accessibilityHint(accessibilityHint ?? "")
    }

    private func syncFromValue() {
        text = value == 0 ? "" : trimmed(value)
    }

    private func trimmed(_ v: Double) -> String {
        if v == v.rounded() { return String(Int(v)) }
        return String(format: "%.2f", v)
    }

    private func clean(_ s: String) -> String {
        var result = ""
        var dotSeen = false
        for ch in s {
            if ch.isNumber { result.append(ch) }
            else if ch == "." && !dotSeen { result.append(ch); dotSeen = true }
        }
        return result
    }
}

/// A labelled percent input (e.g. interest rate).
struct PercentField: View {
    let title: String
    @Binding var value: Double
    var accessibilityHint: String? = nil

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        FieldShell(title: title, trailing: "%") {
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .focused($focused)
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
                .onAppear { syncFromValue() }
                .onChange(of: focused) { _, isFocused in
                    if !isFocused { syncFromValue() }
                }
                .onChange(of: text) { _, newValue in
                    let cleaned = clean(newValue)
                    if cleaned != newValue { text = cleaned }
                    value = Double(cleaned) ?? 0
                }
                .onChange(of: value) { _, _ in
                    if !focused { syncFromValue() }
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(Fmt.percent(value))
        .accessibilityHint(accessibilityHint ?? "")
    }

    private func syncFromValue() {
        text = value == 0 ? "" : trimmed(value)
    }

    private func trimmed(_ v: Double) -> String {
        if v == v.rounded() { return String(Int(v)) }
        return String(format: "%g", v)
    }

    private func clean(_ s: String) -> String {
        var result = ""
        var dotSeen = false
        for ch in s {
            if ch.isNumber { result.append(ch) }
            else if ch == "." && !dotSeen { result.append(ch); dotSeen = true }
        }
        return result
    }
}

/// Shared visual shell for input fields.
private struct FieldShell<Content: View>: View {
    let title: String
    var leading: String? = nil
    var trailing: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 12)
            HStack(spacing: 4) {
                if let leading {
                    Text(leading)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkFaint)
                }
                content
                    .fixedSize(horizontal: false, vertical: true)
                if let trailing {
                    Text(trailing)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            .frame(maxWidth: 170, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
