import SwiftUI

struct IntervalStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    init(label: String, value: Binding<Int>, range: ClosedRange<Int> = 1...90, step: Int = 1) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text)
                Text(Format.intervalLabel(days: value))
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if value - step >= range.lowerBound {
                        value -= step
                        Haptics.selection()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(value <= range.lowerBound ? Brand.text3 : Brand.text)
                }
                .disabled(value <= range.lowerBound)
                .accessibilityLabel("Decrease \(label)")

                Text("\(value)")
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(Brand.text)
                    .frame(minWidth: 36)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("\(value) days")

                Button {
                    if value + step <= range.upperBound {
                        value += step
                        Haptics.selection()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(value >= range.upperBound ? Brand.text3 : Brand.text)
                }
                .disabled(value >= range.upperBound)
                .accessibilityLabel("Increase \(label)")
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Brand.hairline, lineWidth: 0.5))
        }
        .accessibilityElement(children: .contain)
    }
}
