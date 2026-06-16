import SwiftUI
import Charts

/// A single plotted audiogram point. We plot `plotY = -db` so that softer thresholds
/// (lower dB) sit HIGHER on the chart, matching audiogram convention — without relying on
/// any reversed-scale API. Axis labels re-negate to show the true dB value.
private struct AudiogramPoint: Identifiable {
    let id = UUID()
    let ear: Ear
    let frequency: Int
    let db: Double
    var plotY: Double { -db }
}

/// Swift Charts audiogram: log-spaced frequency x-axis, inverted dB y-axis, line+points per ear.
/// Used both full-size (Results) and mini (Home summary).
struct AudiogramChart: View {
    let leftThresholds: [Int: Double]
    let rightThresholds: [Int: Double]
    var maxLevel: Double = 90
    var mini: Bool = false

    /// Log positions for the standard frequencies, so 250→8000 are evenly spaced visually.
    private var xValues: [Double] { Audiometry.frequencies.map { log2(Double($0)) } }
    private var xDomain: ClosedRange<Double> {
        let lo = log2(Double(Audiometry.frequencies.first ?? 250)) - 0.4
        let hi = log2(Double(Audiometry.frequencies.last ?? 8000)) + 0.4
        return lo...hi
    }
    /// In plot (negated) space: top is -10 dB (now +10 after negation), bottom is maxLevel.
    private var yDomain: ClosedRange<Double> {
        let top = max(maxLevel, 90)
        return (-top)...(10)
    }
    /// dB tick values (true dB) we want to show.
    private var yTickDB: [Double] {
        let top = max(maxLevel, 90)
        let step: Double = mini ? 40 : 20
        var ticks: [Double] = []
        var v: Double = 0
        while v <= top { ticks.append(v); v += step }
        return ticks
    }

    private var points: [AudiogramPoint] {
        var pts: [AudiogramPoint] = []
        for f in Audiometry.frequencies {
            if let d = rightThresholds[f] { pts.append(AudiogramPoint(ear: .right, frequency: f, db: d)) }
            if let d = leftThresholds[f] { pts.append(AudiogramPoint(ear: .left, frequency: f, db: d)) }
        }
        return pts
    }

    private func color(for ear: Ear) -> Color { ear == .right ? Theme.earRight : Theme.earLeft }

    var body: some View {
        Chart {
            // Band shading (normal range) for context — only on full chart.
            if !mini {
                RectangleMark(
                    xStart: .value("x0", xDomain.lowerBound),
                    xEnd: .value("x1", xDomain.upperBound),
                    yStart: .value("y0", -HearingBand.normal.lowerBound),
                    yEnd: .value("y1", -HearingBand.normal.upperBound)
                )
                .foregroundStyle(Theme.good.opacity(0.12))
            }

            ForEach(points) { p in
                LineMark(
                    x: .value("Frequency", log2(Double(p.frequency))),
                    y: .value("Threshold", p.plotY),
                    series: .value("Ear", p.ear.rawValue)
                )
                .foregroundStyle(color(for: p.ear))
                .lineStyle(StrokeStyle(lineWidth: mini ? 2 : 2.5))
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Frequency", log2(Double(p.frequency))),
                    y: .value("Threshold", p.plotY)
                )
                .foregroundStyle(color(for: p.ear))
                .symbol(p.ear == .right ? .circle : .square)
                .symbolSize(mini ? 28 : 80)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: xValues) { value in
                if let raw = value.as(Double.self) {
                    let hz = Int(pow(2, raw).rounded())
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    if !mini {
                        AxisValueLabel {
                            Text(Audiometry.label(forFrequency: hz))
                                .font(Theme.rounded(10))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: yTickDB.map { -$0 }) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                if !mini, let plotted = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int((-plotted).rounded()))")
                            .font(Theme.rounded(10))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        }
        .frame(height: mini ? 120 : 260)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Audiogram chart")
        .accessibilityValue(accessibilityDescription)
    }

    /// Describe the chart as data for VoiceOver.
    private var accessibilityDescription: String {
        func describe(_ ear: Ear, _ map: [Int: Double]) -> String {
            let parts = Audiometry.frequencies.compactMap { f -> String? in
                guard let d = map[f] else { return nil }
                return "\(Audiometry.label(forFrequency: f)) \(Int(d.rounded())) decibels"
            }
            return parts.isEmpty ? "" : "\(ear.rawValue) ear: " + parts.joined(separator: ", ") + "."
        }
        let r = describe(.right, rightThresholds)
        let l = describe(.left, leftThresholds)
        let combined = [r, l].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "No thresholds recorded yet." : "Lower numbers mean softer tones heard. \(combined)"
    }
}

/// Legend showing the right/left ear symbols and colors.
struct AudiogramLegend: View {
    var body: some View {
        HStack(spacing: 20) {
            legendItem(color: Theme.earRight, symbol: "circle.fill", label: "Right ear")
            legendItem(color: Theme.earLeft, symbol: "square.fill", label: "Left ear")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend: right ear shown as red circles, left ear shown as blue squares.")
    }

    private func legendItem(color: Color, symbol: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(label)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }
}
