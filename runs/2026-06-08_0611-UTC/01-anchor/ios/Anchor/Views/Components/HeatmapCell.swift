import SwiftUI

/// A single cell in the heatmap grid.
struct HeatmapCell: View {
    var intensity: Double   // 0 = none, 0.5 = partial, 1 = complete
    var color: Color
    var size: CGFloat = 12
    var cornerRadius: CGFloat = 3

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(cellColor)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var cellColor: Color {
        guard intensity > 0 else { return color.opacity(0.10) }
        return color.opacity(0.25 + intensity * 0.75)
    }
}

/// A 12-week contribution heatmap grid used in InsightsView.
struct ContributionHeatmap: View {
    /// columns = weeks (oldest left), rows = days (Sun=0 … Sat=6)
    var weeks: [[Double]]   // weeks[col][row] = intensity 0…1
    var color: Color = Brand.live
    var cellSize: CGFloat = 12
    var spacing: CGFloat = 3

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<weeks.count, id: \.self) { col in
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { row in
                        let intensity = col < weeks.count && row < weeks[col].count ? weeks[col][row] : 0.0
                        HeatmapCell(intensity: intensity, color: color, size: cellSize)
                    }
                }
            }
        }
    }
}
