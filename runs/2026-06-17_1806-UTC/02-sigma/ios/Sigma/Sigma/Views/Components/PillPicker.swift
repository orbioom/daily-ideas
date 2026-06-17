import SwiftUI

/// A compact, themed segmented control. Generic over an Identifiable option type.
struct PillPicker<Option: Identifiable & Equatable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    var accent: Color = Theme.accent
    var onChange: ((Option) -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                    onChange?(option)
                } label: {
                    Text(label(option))
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(isSelected ? Theme.accentInk : Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? accent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(option))
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surfaceDeep)
        )
    }
}
