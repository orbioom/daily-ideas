import SwiftUI

/// A labeled progress bar for a single macro nutrient.
struct MacroBar: View {
    let label: String
    let consumed: Double
    let target: Double
    let color: Color

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }
    private var isOver: Bool { consumed > target }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Brand.text2)
                Spacer()
                Text(Format.grams(consumed))
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text)
                Text("/ \(Format.grams(target))")
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Brand.hairline)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isOver ? Brand.danger : color)
                        .frame(width: max(geo.size.width * fraction, 0), height: 8)
                        .animation(Brand.ease(), value: fraction)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(Format.grams(consumed)) of \(Format.grams(target))")
        .accessibilityValue(Format.percent(fraction))
    }
}
