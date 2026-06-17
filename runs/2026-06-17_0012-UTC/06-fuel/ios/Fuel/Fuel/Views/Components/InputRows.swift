import SwiftUI

/// A labeled stepper row with a formatted value. Calls back with the clamped value.
struct StepperRow: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let value: Double
    let unit: String
    let step: Double
    let range: ClosedRange<Double>
    let format: (Double) -> String
    let onChange: (Double) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FuelTheme.primaryText(scheme))
            Spacer()
            Text("\(format(value)) \(unit)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(FuelTheme.orange)
                .frame(minWidth: 84, alignment: .trailing)
            Stepper(title, value: Binding(
                get: { value },
                set: { onChange(min(max($0, range.lowerBound), range.upperBound)) }
            ), in: range, step: step)
            .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(format(value)) \(unit)")
    }
}

/// Weight entry in the user's display unit, stored canonically in kg.
struct WeightRow: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    @Binding var weightKg: Double
    let unit: WeightUnit

    private var displayValue: Double { unit.fromKg(weightKg) }
    private var range: ClosedRange<Double> { unit == .kg ? 30...300 : 66...660 }

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FuelTheme.primaryText(scheme))
            Spacer()
            Text(String(format: "%.1f %@", displayValue, unit.label))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(FuelTheme.orange)
                .frame(minWidth: 84, alignment: .trailing)
            Stepper(title, value: Binding(
                get: { displayValue },
                set: { newDisplay in
                    let clamped = min(max(newDisplay, range.lowerBound), range.upperBound)
                    weightKg = unit.toKg(clamped)
                }
            ), in: range, step: unit.step)
            .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(String(format: "%.1f %@", displayValue, unit.label))
    }
}

/// Height entry — cm via stepper, or feet+inches via two pickers.
struct HeightRow: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var heightCm: Double
    let unit: HeightUnit

    var body: some View {
        Group {
            if unit == .cm {
                HStack {
                    Text("Height")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FuelTheme.primaryText(scheme))
                    Spacer()
                    Text(String(format: "%.0f cm", heightCm))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(FuelTheme.orange)
                        .frame(minWidth: 84, alignment: .trailing)
                    Stepper("Height", value: Binding(
                        get: { heightCm },
                        set: { heightCm = min(max($0, 120), 230) }
                    ), in: 120...230, step: 1)
                    .labelsHidden()
                }
            } else {
                let fi = FeetInches.fromCm(heightCm)
                HStack {
                    Text("Height")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FuelTheme.primaryText(scheme))
                    Spacer()
                    Picker("Feet", selection: Binding(
                        get: { fi.feet },
                        set: { heightCm = FeetInches(feet: $0, inches: fi.inches).cm }
                    )) {
                        ForEach(3...8, id: \.self) { Text("\($0) ft").tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(FuelTheme.orange)

                    Picker("Inches", selection: Binding(
                        get: { fi.inches },
                        set: { heightCm = FeetInches(feet: fi.feet, inches: $0).cm }
                    )) {
                        ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(FuelTheme.orange)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Height")
    }
}

/// A tappable selectable row with a checkmark, optional detail & trailing text.
struct SelectableRow: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let detail: String?
    let trailing: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? FuelTheme.orange : FuelTheme.secondaryText(scheme))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FuelTheme.primaryText(scheme))
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(FuelTheme.secondaryText(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + (detail.map { ". \($0)" } ?? ""))
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}
