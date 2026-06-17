import SwiftUI

/// A row of selectable avatar colors from the fixed palette.
struct ColorPaletteRow: View {
    @Binding var selected: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.inkSoft)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(AvatarPalette.colors, id: \.self) { hex in
                    Button {
                        selected = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: UInt(hex)))
                            .frame(height: 52)
                            .overlay(
                                Circle().strokeBorder(
                                    selected == hex ? Theme.ink : .white.opacity(0.6),
                                    lineWidth: selected == hex ? 4 : 2
                                )
                            )
                            .overlay {
                                if selected == hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 20, weight: .heavy))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color option")
                    .accessibilityAddTraits(selected == hex ? [.isSelected, .isButton] : .isButton)
                }
            }
        }
    }
}
