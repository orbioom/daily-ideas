import SwiftUI

/// Compact per-ear PTA + classification chip.
struct EarSummaryRow: View {
    let analysis: EarAnalysis

    private var earColor: Color { analysis.ear == .right ? Theme.earRight : Theme.earLeft }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(earColor.opacity(0.18))
                Text(analysis.ear.short)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(earColor)
            }
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(analysis.ear.rawValue) ear")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                if let pta = analysis.pta {
                    Text("PTA \(Int(pta.rounded())) dB")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Text("Not measurable")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            Spacer()

            if let band = analysis.band {
                BandChip(band: band)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if let pta = analysis.pta, let band = analysis.band {
            return "\(analysis.ear.rawValue) ear, pure tone average \(Int(pta.rounded())) decibels, \(band.title)."
        }
        return "\(analysis.ear.rawValue) ear, not measurable."
    }
}

/// Colored band pill.
struct BandChip: View {
    let band: HearingBand
    var body: some View {
        Text(band.title)
            .font(Theme.rounded(12, .semibold))
            .foregroundStyle(band.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(band.color.opacity(0.16))
            )
    }
}
