import SwiftUI

/// Horizontal scrollable palette: each swatch shows its number; selected is ringed.
struct PaletteBar: View {
    @ObservedObject var model: ColoringViewModel

    var body: some View {
        VStack(spacing: 8) {
            if !model.recentColorIndices.isEmpty {
                recentRow
            }
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(model.palette.colors.enumerated()), id: \.offset) { index, color in
                            swatch(index: index, color: color)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .onChange(of: model.selectedColorIndex) { _, new in
                    withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(new, anchor: .center) }
                }
            }
        }
        .padding(.vertical, 10)
        .background(Theme.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }

    private var recentRow: some View {
        HStack(spacing: 8) {
            Text("Recent")
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.inkFaint)
            ForEach(Array(model.recentColorIndices.enumerated()), id: \.offset) { _, idx in
                Button {
                    model.selectColor(idx)
                } label: {
                    Circle()
                        .fill(model.palette.color(at: idx))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().strokeBorder(Theme.hairline))
                }
                .accessibilityLabel("Recent color number \(idx + 1)")
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func swatch(index: Int, color: Color) -> some View {
        let isSelected = index == model.selectedColorIndex
        return Button {
            model.selectColor(index)
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1))
                Text("\(index + 1)")
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(contrastInk(for: color))
            }
            .overlay(
                Circle()
                    .strokeBorder(Theme.accent, lineWidth: isSelected ? 3 : 0)
                    .frame(width: 48, height: 48)
            )
            .frame(width: 50, height: 50)
        }
        .accessibilityLabel("Color number \(index + 1)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// Choose black or white label text for legibility on the swatch.
    private func contrastInk(for color: Color) -> Color {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return .black }
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.6 ? Color(hex: 0x2A2530) : .white
    }
}
