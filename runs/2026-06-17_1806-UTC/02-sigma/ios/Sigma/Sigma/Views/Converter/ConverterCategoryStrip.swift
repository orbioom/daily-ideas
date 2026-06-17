import SwiftUI

/// Horizontal scrolling strip of conversion categories.
struct ConverterCategoryStrip: View {
    let categories: [ConvCategory]
    let selected: ConvCategory
    let accent: Color
    let onSelect: (ConvCategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { cat in
                    let isSelected = cat.id == selected.id
                    Button {
                        onSelect(cat)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.systemImage)
                            Text(cat.name)
                        }
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(isSelected ? Theme.accentInk : Theme.inkSoft)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(isSelected ? accent : Theme.surface))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(cat.name)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
