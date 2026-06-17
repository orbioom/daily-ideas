import SwiftUI

/// A labeled numeric input row with a leading symbol and decimal keypad.
/// Shows a calm inline warning when the text is non-empty but unparseable.
struct AbodeNumberField: View {
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
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AbodeTheme.primaryText(scheme))

            HStack(spacing: 8) {
                Text(symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    .frame(minWidth: 14)
                    .accessibilityHidden(true)
                TextField(prompt, text: $text)
                    .keyboardType(.decimalPad)
                    .font(AbodeTheme.figure(.body, weight: .medium))
                    .foregroundStyle(AbodeTheme.primaryText(scheme))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AbodeTheme.subtleSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isInvalid ? AbodeTheme.danger.opacity(0.7) : Color.clear, lineWidth: 1)
            )

            if isInvalid {
                Text("Enter a valid, non-negative number.")
                    .font(.caption2)
                    .foregroundStyle(AbodeTheme.danger)
            } else if let help {
                Text(help)
                    .font(.caption2)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(text.isEmpty ? "empty" : "\(symbol)\(text)")
    }
}

/// A segmented chip picker for a fixed set of choices (e.g. loan term).
struct AbodeSegmentPicker<Value: Hashable>: View {
    let title: String
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    var onChange: (() -> Void)? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AbodeTheme.primaryText(scheme))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.value) { option in
                        Button {
                            selection = option.value
                            onChange?()
                        } label: {
                            Text(option.label)
                                .abodeChip(selected: selection == option.value)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.label)
                        .accessibilityAddTraits(selection == option.value ? .isSelected : [])
                    }
                }
            }
        }
    }
}

/// A read-only labeled statistic row (label left, value right, monospaced figure).
struct StatRow: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let value: String
    var emphasis: Bool = false
    var accent: Color? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(emphasis ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(emphasis ? AbodeTheme.primaryText(scheme) : AbodeTheme.secondaryText(scheme))
            Spacer(minLength: 12)
            Text(value)
                .font(AbodeTheme.figure(emphasis ? .body : .subheadline, weight: emphasis ? .bold : .medium))
                .foregroundStyle(accent ?? AbodeTheme.primaryText(scheme))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
