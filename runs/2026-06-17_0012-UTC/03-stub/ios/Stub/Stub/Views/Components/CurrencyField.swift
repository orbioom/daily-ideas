import SwiftUI

/// A labeled numeric input row with a leading symbol and decimal keypad.
/// Validates lightly: shows a subtle warning tint when the text is non-empty
/// but unparseable.
struct CurrencyField: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    var symbol: String = "$"
    var prompt: String = "0"
    @Binding var text: String
    var help: String? = nil

    private var isInvalid: Bool {
        !text.isEmpty && Parse.decimal(text) == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(StubTheme.secondaryText(scheme))
                    .frame(width: 16)
                    .accessibilityHidden(true)
                TextField(prompt, text: $text)
                    .keyboardType(.decimalPad)
                    .font(StubTheme.figureFont(.body, weight: .medium))
                    .foregroundStyle(StubTheme.primaryText(scheme))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(StubTheme.subtleSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isInvalid ? StubTheme.federal.opacity(0.7) : Color.clear, lineWidth: 1)
            )

            if isInvalid {
                Text("Enter a valid, non-negative number.")
                    .font(.caption2)
                    .foregroundStyle(StubTheme.federal)
            } else if let help {
                Text(help)
                    .font(.caption2)
                    .foregroundStyle(StubTheme.secondaryText(scheme))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(text.isEmpty ? "empty" : text)
    }
}

/// A small section header used inside the calculator form.
struct FieldLabel: View {
    @Environment(\.colorScheme) private var scheme
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(StubTheme.primaryText(scheme))
    }
}
