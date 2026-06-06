import SwiftUI

/// A calm minutes heatmap: rows are weeks (oldest top), columns Mon→Sun. Cell tint
/// deepens with minutes. Each cell carries a VoiceOver label with the date + minutes,
/// so the data is never color-only.
struct HeatmapGrid: View {
    /// weeks[row][col] = (day, minutes). Mon→Sun per row.
    var weeks: [[(day: Date, minutes: Int)]]

    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    /// The busiest day in the grid, used to scale the tint. Floored at 1.
    private var maxMinutes: Int {
        max(1, weeks.flatMap { $0 }.map { $0.minutes }.max() ?? 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 6) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                        cellView(cell.day, cell.minutes)
                    }
                }
            }

            legend
                .padding(.top, 4)
        }
    }

    private func cellView(_ day: Date, _ minutes: Int) -> some View {
        let intensity = min(1.0, Double(minutes) / Double(maxMinutes))
        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(fill(for: minutes, intensity: intensity))
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 0.5)
            )
            .accessibilityElement()
            .accessibilityLabel(day.formatted(date: .abbreviated, time: .omitted))
            .accessibilityValue(minutes == 0 ? "No practice" : "\(minutes) minutes")
    }

    private func fill(for minutes: Int, intensity: Double) -> Color {
        guard minutes > 0 else { return Brand.text3.opacity(0.12) }
        // Floor the opacity so even short sessions read as "present".
        return Brand.live.opacity(0.25 + 0.6 * intensity)
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Text("Less").font(.caption2).foregroundStyle(Brand.text3)
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(i == 0 ? Brand.text3.opacity(0.12)
                                 : Brand.live.opacity(0.25 + 0.6 * (Double(i) / 4.0)))
                    .frame(width: 14, height: 14)
            }
            Text("More").font(.caption2).foregroundStyle(Brand.text3)
            Spacer()
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HeatmapGrid(weeks: Insights.weeklyHeatmap(
        sessions: [],
        weeks: 6
    ))
    .padding()
    .background(Brand.pageBackground)
}
