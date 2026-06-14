import SwiftUI

/// Term editor that respects the user's preferred unit (years or months).
struct TermField: View {
    @Binding var termMonths: Int
    @Environment(AppSettings.self) private var settings

    @State private var text: String = ""
    @FocusState private var focused: Bool

    private var unit: TermUnit { settings.termUnit }

    var body: some View {
        HStack(spacing: 10) {
            Text("Term")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 12)
            HStack(spacing: 4) {
                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
                    .onAppear { syncFromValue() }
                    .onChange(of: focused) { _, f in if !f { syncFromValue() } }
                    .onChange(of: text) { _, newValue in
                        let digits = newValue.filter(\.isNumber)
                        if digits != newValue { text = digits }
                        applyText(digits)
                    }
                    .onChange(of: termMonths) { _, _ in if !focused { syncFromValue() } }
                    .onChange(of: settings.termUnitRaw) { _, _ in syncFromValue() }
                Text(unit == .years ? "yr" : "mo")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Term")
        .accessibilityValue(Fmt.termDescription(months: termMonths))
    }

    private func syncFromValue() {
        if unit == .years {
            // Show whole years; round to nearest for display.
            let years = Int((Double(termMonths) / 12.0).rounded())
            text = years == 0 ? "" : String(years)
        } else {
            text = termMonths == 0 ? "" : String(termMonths)
        }
    }

    private func applyText(_ digits: String) {
        let n = Int(digits) ?? 0
        if unit == .years {
            termMonths = min(600, max(0, n * 12))
        } else {
            termMonths = min(600, max(0, n))
        }
    }
}

/// Editor for the month at which a one-time extra payment is applied.
struct OneTimeMonthField: View {
    @Binding var month: Int
    let maxMonth: Int

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("Apply at month #")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 12)
            TextField("1", text: $text)
                .keyboardType(.numberPad)
                .focused($focused)
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
                .onAppear { syncFromValue() }
                .onChange(of: focused) { _, f in if !f { syncFromValue() } }
                .onChange(of: text) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue { text = digits }
                    let n = Int(digits) ?? 0
                    month = min(max(1, maxMonth), max(0, n))
                }
                .onChange(of: month) { _, _ in if !focused { syncFromValue() } }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("One-time payment applied at month number")
        .accessibilityValue(month > 0 ? "\(month)" : "not set")
    }

    private func syncFromValue() {
        text = month == 0 ? "" : String(month)
    }
}
