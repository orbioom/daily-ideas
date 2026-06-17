import SwiftUI

/// Shows a value simultaneously in DEC / HEX / BIN / OCT plus a grouped binary line.
/// Tapping a base row selects it as the active input base.
struct BaseReadoutCard: View {
    let value: UInt64
    let width: BitWidth
    let inputBase: NumberBase
    let accent: Color
    let onSelectBase: (NumberBase) -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach(NumberBase.allCases) { base in
                baseRow(base)
            }
            HStack(alignment: .top) {
                Text("Binary")
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.inkFaint)
                Spacer()
                Text(BaseConverter.groupedBinary(value, width: width))
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .accessibilityLabel("Binary \(BaseConverter.groupedBinary(value, width: width))")
            }
            .padding(.top, 4)
        }
        .card()
    }

    private func baseRow(_ base: NumberBase) -> some View {
        let isSelected = base == inputBase
        return Button {
            onSelectBase(base)
        } label: {
            HStack {
                Text(base.label)
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(isSelected ? Theme.accentInk : Theme.inkSoft)
                    .frame(width: 46)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isSelected ? accent : Theme.surfaceDeep))
                Spacer()
                Text(BaseConverter.format(value, base: base, width: width))
                    .font(Theme.rounded(26, .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(base.label) \(BaseConverter.format(value, base: base, width: width))")
        .accessibilityHint("Selects \(base.label) as the input base")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
