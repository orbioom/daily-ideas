import SwiftUI
import SwiftData

struct PaletteListView: View {
    @Query(sort: \Palette.createdAt, order: .reverse) private var palettes: [Palette]
    @State private var selectedPalette: Palette?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SwatchTheme.bg.ignoresSafeArea()

                if palettes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 56))
                            .foregroundStyle(SwatchTheme.subtleText.opacity(0.5))
                        Text("No palettes yet")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(SwatchTheme.subtleText)
                        Text("Extract colors from a photo to\ncreate your first palette.")
                            .font(.body)
                            .foregroundStyle(SwatchTheme.subtleText.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(palettes) { palette in
                                PaletteCard(palette: palette)
                                    .onTapGesture {
                                        selectedPalette = palette
                                    }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Palettes")
            .sheet(item: $selectedPalette) { palette in
                PaletteDetailView(palette: palette)
            }
        }
    }
}

struct PaletteCard: View {
    let palette: Palette

    private var sortedColors: [SwatchColor] {
        palette.colors.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Color strip
            HStack(spacing: 0) {
                ForEach(sortedColors) { sc in
                    sc.color
                }
            }
            .frame(height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text(palette.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SwatchTheme.accent)
                    .lineLimit(1)
                Text(palette.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(SwatchTheme.subtleText)
            }
            .padding(10)
        }
        .background(SwatchTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: SwatchTheme.shadow, radius: 6, y: 3)
    }
}
