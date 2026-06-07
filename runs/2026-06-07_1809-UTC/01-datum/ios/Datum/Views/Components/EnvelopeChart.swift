import SwiftUI
import Charts

/// A scenario point to plot on the envelope chart.
struct ChartScenarioPoint: Identifiable {
    let id = UUID()
    let label: String
    let cg: Double
    let weight: Double
    let isOK: Bool
}

/// A CG envelope chart: a translucent filled + stroked polygon of the envelope
/// with optional scenario points colored by in/out status. Built on Swift Charts
/// so axes, gridlines and Dynamic Type come for free. Fully accessible.
struct EnvelopeChart: View {
    let envelope: [EnvelopeVertex]
    var points: [ChartScenarioPoint] = []
    var height: CGFloat = 280
    /// A one-line summary used as the chart's accessibility label.
    var accessibilitySummary: String = "CG envelope chart"

    private var closedPolygon: [EnvelopeVertex] {
        guard let first = envelope.first else { return [] }
        return envelope + [first]   // close the loop for the area/line marks
    }

    private var xDomain: ClosedRange<Double> {
        let cgs = envelope.map(\.cg) + points.map(\.cg)
        guard let lo = cgs.min(), let hi = cgs.max(), lo < hi else { return 0...1 }
        let pad = max(0.5, (hi - lo) * 0.08)
        return (lo - pad)...(hi + pad)
    }

    private var yDomain: ClosedRange<Double> {
        let ws = envelope.map(\.weight) + points.map(\.weight)
        guard let lo = ws.min(), let hi = ws.max(), lo < hi else { return 0...1 }
        let pad = max(20, (hi - lo) * 0.08)
        return (lo - pad)...(hi + pad)
    }

    var body: some View {
        Group {
            if envelope.count < 3 {
                EmptyStateView(
                    icon: "chart.xyaxis.line",
                    title: "No envelope",
                    message: "Add at least three CG envelope points to plot the chart."
                )
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        Chart {
            // Envelope perimeter stroke (a single closed series).
            ForEach(Array(closedPolygon.enumerated()), id: \.offset) { _, v in
                LineMark(
                    x: .value("CG (in)", v.cg),
                    y: .value("Weight (lb)", v.weight),
                    series: .value("Series", "Envelope")
                )
                .foregroundStyle(Brand.info)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.linear)
            }
            // Scenario points.
            ForEach(points) { p in
                PointMark(
                    x: .value("CG (in)", p.cg),
                    y: .value("Weight (lb)", p.weight)
                )
                .foregroundStyle(p.isOK ? Brand.live : Brand.danger)
                .symbolSize(120)
                .annotation(position: .top, spacing: 2) {
                    Text(p.label)
                        .font(Brand.mono(9, weight: .medium))
                        .foregroundStyle(Brand.text2)
                }
            }
        }
        // True polygon fill drawn behind the marks via the chart's coordinate space.
        .chartBackground { proxy in
            GeometryReader { geo in
                if let plot = proxy.plotFrame {
                    let rect = geo[plot]
                    polygonPath(in: rect, proxy: proxy)
                        .fill(Brand.info.opacity(0.16))
                }
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine().foregroundStyle(Brand.hairline)
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(String(format: "%.0f", d))
                            .font(Brand.mono(9))
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Brand.hairline)
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(String(format: "%.0f", d))
                            .font(Brand.mono(9))
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .chartXAxisLabel("CG arm (in)", alignment: .center)
        .chartYAxisLabel("Weight (lb)")
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("CG envelope chart")
        .accessibilityValue(accessibilitySummary)
    }

    /// Builds the filled envelope polygon in screen coordinates using the chart's
    /// value-to-position mapping. `plotFrame` positions are relative to the plot
    /// area origin, so we offset by the plot rect's origin.
    private func polygonPath(in rect: CGRect, proxy: ChartProxy) -> Path {
        var path = Path()
        var started = false
        for v in envelope {
            guard let px = proxy.position(forX: v.cg),
                  let py = proxy.position(forY: v.weight) else { continue }
            let point = CGPoint(x: rect.origin.x + px, y: rect.origin.y + py)
            if started {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                started = true
            }
        }
        if started { path.closeSubpath() }
        return path
    }
}
