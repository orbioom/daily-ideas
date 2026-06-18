import SwiftUI

/// Horizontal reference-range band with optimal (green) and standard (blue)
/// zones and a marker dot at the value's position. Clinical, calm look.
struct RangeBandView: View {
    let marker: Biomarker
    let sex: BiologicalSex
    let assessment: RangeAssessment
    var showOptimal: Bool = true

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let stops = RangeEngine.bandStops(marker: marker, sex: sex)
            ZStack(alignment: .leading) {
                // Base track (out-of-range backdrop).
                Capsule()
                    .fill(Theme.bad.opacity(0.16))
                    .frame(height: 10)

                // Standard in-range band.
                bandSegment(from: stops.stdLow, to: stops.stdHigh, width: w, color: Theme.okay.opacity(0.28))

                // Optimal band on top.
                if showOptimal {
                    bandSegment(from: stops.optLow, to: stops.optHigh, width: w, color: Theme.good.opacity(0.40))
                }

                // Marker dot.
                Circle()
                    .fill(assessment.status.color)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().strokeBorder(Theme.surface, lineWidth: 2))
                    .position(x: dotX(width: w), y: 5)
            }
            .frame(height: 16)
        }
        .frame(height: 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Value position in range")
        .accessibilityValue(assessment.status.rawValue)
    }

    private func dotX(width: CGFloat) -> CGFloat {
        let p = CGFloat(min(1, max(0, assessment.position)))
        // Inset so the dot stays fully visible at the extremes.
        let inset: CGFloat = 8
        let usable = max(0, width - inset * 2)
        return inset + usable * p
    }

    @ViewBuilder
    private func bandSegment(from: Double?, to: Double?, width: CGFloat, color: Color) -> some View {
        let lo = CGFloat(min(1, max(0, from ?? 0)))
        let hi = CGFloat(min(1, max(0, to ?? 1)))
        let x0 = min(lo, hi) * width
        let x1 = max(lo, hi) * width
        let segWidth = max(0, x1 - x0)
        Capsule()
            .fill(color)
            .frame(width: segWidth, height: 10)
            .offset(x: x0)
    }
}
